class TasksController < ApplicationController
  def create
    request.body.rewind
    payload = JSON.parse(request.body.read)

    task_id = payload['pull_request']['head']['ref'].split('-').last
    action = payload['action'].to_sym
    labels = payload['pull_request']['labels'] || []
    status = nil

    labels.each do |label|
      status = label_in_hash?(label['name']) ? label['name'] : nil
      break if status
    end

    ClickUp.move_task(task_id, status)
  end

  private
    def label_in_hash?(name)
      ClickUp::LABEL_MAPPING.keys.include?(name)
    end
end
