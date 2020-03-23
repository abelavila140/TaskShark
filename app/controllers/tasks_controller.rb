class TasksController < ApplicationController
  def create
    request.body.rewind

    event_type = request.headers['X-GitHub-Event'].to_sym
    begin
      self.send(event_type)
    rescue
      head :no_content
    end
  end

  def pull_request
    logger.info "IN PR"

    @task_payload = task_payload(payload['pull_request']['head']['ref'])
    task_id = @task_payload['id']
    logger.info task_id
    return head :no_content if task_id.nil?

    action = payload['action'].to_sym
    labels = payload['pull_request']['labels'] || []
    github_url = payload['pull_request']['html_url']
    status = nil

    if action == :closed
      status = 'merged'
    else
      labels.each { |label| status = label['name'] if label_in_hash?(label['name']) }
    end

    logger.info "STATUS: #{status}"
    current_status = ClickUp::LABELS.invert[@task_payload['status']['status']]
    logger.info "CURRENT STATUS: #{current_status}"

    logger.info "User: #{fetch_username}"
    ClickUp.move_task(task_id, fetch_username, status) unless current_status == status
    ClickUp.attach_github_pr(task_id, fetch_username, github_url) unless attached_pr?

    head :ok, json: "Status Changed"
  end

  def push
    logger.debug "Pushed"
    logger.debug first_push?.inspect
    return head :no_content unless first_push?

    branch = payload['ref'].gsub('refs/heads/', '')
    @task_payload = task_payload(branch, true)
    logger.info "Branch : #{branch}"
    logger.info "Task: #{@task_payload['id']}"
    return head :no_content, json: "No Task ID" unless @task_payload['id']

    username = payload['pusher']['name']
    repo = payload['repository']['full_name']
    organization = repo.split('/').first

    body = {
      title: @task_payload['name'],
      head: "#{organization}:#{branch}",
      base: 'master',
      body: "[content]\r\n\r\nTasks Details: #{@task_payload['url']}"
    }

    logger.info "username: #{username}"
    logger.info "Repo: #{repo}, Org: #{organization}"

    Github.create_pull_request(repo, username, body)

    logger.info "Created PR!"

    render :ok, json: { body: "Pull Request Created" }
  end

  private
    def payload
      @payload ||= JSON.parse(request.body.read)
    end

    def label_in_hash?(name)
      ClickUp::LABELS.keys.include?(name)
    end

    def task_payload(branch, is_push=false)
      logger.info "task_payload"
      branch_task_id = branch.split('-').last
      task = ClickUp.verify_task_id(branch_task_id)
      logger.info task.inspect
      return task if task.present? || is_push

      branch_task_id = payload['pull_request']['title'].split('|').last.strip
      ClickUp.verify_task_id(branch_task_id)
    end

    def first_push?
      payload['before'].gsub('0', '').blank?
    end

    def fetch_username
      username = payload['sender']['login']
      ClickUp::USERS.keys.include?(username) ? username : 'default'
    end

    def attached_pr?
      @task_payload['custom_fields'].find { |fields| fields['id'] == ClickUp.field_id }['value']
    end
end
