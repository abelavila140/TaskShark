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
    pr_state = payload['pull_request']['state'].to_sym
    github_body = payload['pull_request']['body']
    status = nil

    if action == :closed
      status = 'merged'
    else
      return head :no_content if pr_state == :closed
      labels.each { |label| status = label['name'] if label_in_hash?(label['name']) }
    end

    logger.info "STATUS: #{status}"
    current_status = ClickUp::LABELS.invert[@task_payload['status']['status']]
    logger.info "CURRENT STATUS: #{current_status}"

    logger.info "User: #{fetch_username}"
    ClickUp.move_task(task_id, fetch_username, status) unless current_status == status
    ClickUp.attach_github_url(task_id, fetch_username, github_url) unless attached_pr?

    # di extra stuffs when task is a subtask
    label_names = labels.map { |l| l['name'] }
    return head :ok unless @task_payload['parent']

    # Attach all dependent PRs to body
    parent_task = ClickUp.verify_task_id(@task_payload['parent'])
    subtasks = ClickUp.subtasks(parent_task['list']['id'], parent_task['id'])['tasks']

    dependencies = []
    update_dependencies = false
    subtasks.each do |subtask|
      tags = subtask['tags'].map { |t| t['name'] }
      Rails.logger.debug "TAGS:"
      Rails.logger.debug tags.inspect
      Rails.logger.debug "SUB ID: TASKID"
      Rails.logger.debug "#{subtask['id']} : #{task_id}"
      next unless (tags & ['frontend', 'api', 'legacy']).present? && subtask['id'] != task_id

      github_url = subtask['custom_fields'].find { |f| f['name'] == 'GitHub PR' }['value']

      if github_url.present? && !github_body.include?(github_url)
        dependencies << github_url
        update_dependencies = true
      end
    end

    Rails.logger.debug dependencies.inspect
    Rails.logger.debug update_dependencies.inspect

    # split GH body by breaks
    if update_dependencies
      body_breaks = github_body.split(/\r\n/)
      has_previous_dependencies = github_body.include?('Relies on:')
      dependencies_str = "Relies on: #{dependencies.join(', ')}"

      body_breaks.map! do |str|
        if has_previous_dependencies && str.include?('Relies on:')
          dependencies_str
        elsif str.include?('Tasks Details:') && !has_previous_dependencies
          "#{dependencies_str}\r\n#{str}"
        else
          str
        end
      end

      username = payload['pull_request']['user']['login']
      repo = payload['repository']['full_name']
      body = {
        body: body_breaks.join("\r\n")
      }
      logger.debug body.inspect
      a = Github.update_pull_request(payload['number'], repo, username, body)
      logger.debug a.inspect
    end

    logger.info "LETS MOVE SOME STUFF!"

    parent_status = parent_task['status']['status']
    parent_status_position = ClickUp::STATUSES[parent_status]
    previous_position = nil
    qa_subtask = nil

    subtasks.each do |subtask|
      tags = subtask['tags'].map { |t| t['name'] }
      qa_subtask = subtask if tags.include?('qa review')
      next unless (tags & ['frontend', 'api', 'legacy', 'migration']).present?

      status_position = ClickUp::STATUSES[subtask['status']['status']]
      if previous_position.nil? || status_position < previous_position
        parent_status_position = status_position
      end

      previous_position = status_position
    end

    qa_status = qa_subtask['status']['status']

    status = ClickUp::STATUSES.invert[parent_status_position]
    if status == 'in qa review' && qa_status != status
      ClickUp.move_task(qa_subtask['id'], fetch_username, 'QA Review')
    elsif parent_status == 'in qa review' && status != parent_status && qa_status == 'in qa review'
      ClickUp.move_task(qa_subtask['id'], fetch_username, 'backlog')
    end

    logger.info "MOVE PARENT POSITION? #{parent_status_position}"
    return head :ok if parent_status == status

    ClickUp.move_task(parent_task['id'], fetch_username, ClickUp::LABELS.invert[status])

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

    # Attach all dependent PRs to body
    dependencies = []
    if @task_payload['parent']
      parent_task = ClickUp.verify_task_id(@task_payload['parent'])
      subtasks = ClickUp.subtasks(parent_task['list']['id'], parent_task['id'])['tasks']

      subtasks.each do |subtask|
        tags = subtask['tags'].map { |t| t['name'] }
        next unless (tags & ['frontend', 'api', 'legacy']).present?

        github_url = subtask['custom_fields'].find { |f| f['name'] == 'GitHub PR' }['value']

        dependencies << github_url if github_url.present?
      end
    end

    dependencies_str = dependencies.present? ? "\r\nRelies on: #{dependencies.join(', ')}" : ''

    username = payload['pusher']['name']
    repo = payload['repository']['full_name']
    organization = repo.split('/').first

    body = {
      title: @task_payload['parent'] ? parent_task['name'] : @task_payload['name'],
      head: "#{organization}:#{branch}",
      base: 'master',
      body: "[content]\r\n#{dependencies_str}\r\nTasks Details: #{@task_payload['url']}"
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
      if payload['pull_request']
        branch_task_id = payload['pull_request']['title'].split('|').last&.strip
        task = ClickUp.verify_task_id(branch_task_id)
        return task if task.present?
      end

      branch_task_id = branch.split('-').last
      task = ClickUp.verify_task_id(branch_task_id)
      logger.info task.inspect
      return task if task.present?

      branch_task_id = branch.split('-cp').last
      task = ClickUp.verify_task_id(branch_task_id)
      return task if task.present? || is_push
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
