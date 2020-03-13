require 'rest-client'

class ClickUp
  LABEL_MAPPING = {
    nil => 'in development',
    'Dev Review' => 'in dev review',
    'QA Review' => 'in qa review',
    'merged' => 'ready to deploy'
  }

  def self.verify_task_id(task_id)
    begin
      response = request(task_id)
      JSON.parse(response.body)['id']
    rescue
      nil
    end
  end

  def self.move_task(task_id, status)
    request(task_id, status: LABEL_MAPPING[status])
  end

  def self.request(task_id, body={})
    ::RestClient::Request.execute(
      method: :put,
      url: "https://api.clickup.com/api/v1/task/#{task_id}",
      headers: {
        'Authorization': ENV['API_KEY'],
        'Content-Type': 'application/json'
      },
      payload: body
    )
  end
end
