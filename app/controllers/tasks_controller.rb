class TasksController < ApplicationController
  def create
    request.body.rewind

    task_id = fetch_task_id
    return head :no_content if task_id.nil?

    action = payload['action'].to_sym
    labels = payload['pull_request']['labels'] || []
    status = nil

    if action == :labeled || action == :unlabled
      labels.each { |label| status = label['name'] if label_in_hash?(label['name']) }
    elsif action == :closed
      status = 'merged'
    end

    ClickUp.move_task(task_id, status)
  end

  private
    def payload
      @payload ||= JSON.parse(request.body.read)
    end

    def label_in_hash?(name)
      ClickUp::LABEL_MAPPING.keys.include?(name)
    end

    def fetch_task_id
      branch_task_id = payload['pull_request']['head']['ref'].split('-').last
      return task_id if task_id = ClickUp.verify_task_id(branch_task_id)

      branch_task_id = payload['pull_request']['title'].split('|').last.strip
      ClickUp.verify_task_id(branch_task_id)
    end
end
