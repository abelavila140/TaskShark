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

    task_payload = task_payload(payload['pull_request']['head']['ref'])
    task_id = task_payload['id']
    logger.info task_id
    return head :no_content if task_id.nil?

    action = payload['action'].to_sym
    labels = payload['pull_request']['labels'] || []
    status = nil

    if action == :closed
      status = 'merged'
    else
      labels.each { |label| status = label['name'] if label_in_hash?(label['name']) }
    end

    logger.info "STATUS: #{status}"
    current_status = ClickUp::LABELS.invert[task_payload['status']['status']]
    logger.info "CURRENT STATUS: #{current_status}"

    return head :no_content if current_status == status

    logger.info "User: #{fetch_username}"
    ClickUp.move_task(task_id, fetch_username, status)

    head :ok, json: "Status Changed"
  end

  def push
    return head :no_content unless first_push?

    branch = payload['ref'].gsub('refs/heads/', '')
    task_payload = task_payload(branch, true)
    return head :no_content, json: "No Task ID" unless task_payload['id']

    username = payload['pusher']['name']
    repo = payload['repository']['full_name']
    organization = repo.split('/').first

    body = {
      title: task_payload['name'],
      head: "#{organization}:#{branch}",
      base: 'master',
      body: "[content]\r\n\r\nTasks Details: #{task_payload['url']}"
    }

    Github.create_pull_request(repo, username, body)

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
      branch_task_id = branch.split('-').last
      task = ClickUp.verify_task_id(branch_task_id)
      return task if task.present? || is_push

      branch_task_id = payload['pull_request']['title'].split('|').last.strip
      ClickUp.verify_task_id(branch_task_id)
    end

    def first_push?
      payload['before'].gsub('0', '').blank?
    end

    def fetch_username
      username = payload['pull_request']['user']['login']
      ClickUp::USERS.keys.include?(username) ? username : 'default'
    end
end
