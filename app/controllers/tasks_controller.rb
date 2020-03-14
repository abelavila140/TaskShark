class TasksController < ApplicationController
  def create
    request.body.rewind

    event_type = request.headers['X-GitHub-Event'].to_sym
    self.send(event_type) rescue nil

    head :method_not_allowed
  end

  def pull_request
    task_id = task_payload(payload['pull_request']['head']['ref'])['id']
    return head :no_content if task_id.nil?

    action = payload['action'].to_sym
    labels = payload['pull_request']['labels'] || []
    status = nil

    if action == :closed
      status = 'merged'
    else
      labels.each { |label| status = label['name'] if label_in_hash?(label['name']) }
    end

    ClickUp.move_task(task_id, status)

    head :ok, json: "Status Changed"
  end

  def push
    return head :no_content unless first_push?

    branch = payload['ref'].gsub('refs/heads/', '')
    task_payload = task_payload(branch, true)
    return head :no_content if task_payload['id']

    repo = payload['repository']['full_name']
    body = {
      title: task_payload['name'],
      head: branch,
      base: 'master',
      body: "/n/nTasks Details: #{task_payload['url']}"
    }

    GitHub.create_pull_request(repo, body)

    head :ok, json: "Pull Request Created"
  end

  private
    def payload
      @payload ||= JSON.parse(request.body.read)
    end

    def label_in_hash?(name)
      ClickUp::LABEL_MAPPING.keys.include?(name)
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
end
