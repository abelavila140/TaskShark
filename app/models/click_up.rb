require 'rest-client'

class ClickUp

  LABEL_MAPPING = { 'Dev Review' => 'in dev/testing', nil => 'backlog' }

  def self.move_task(task_id, status)
    ::RestClient::Request.execute(
      method: :put,
      url: "https://api.clickup.com/api/v1/task/#{task_id}",
      headers: {
        'Authorization': 'pk_4404988_BR1FJXX02JELDZ8KDVCNOCV4RYT0P2YX',
        'Content-Type': 'application/json'
      },
      payload: { status: LABEL_MAPPING[status] }
    )
  end
end
