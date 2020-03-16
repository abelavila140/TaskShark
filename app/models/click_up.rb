require 'rest-client'

class ClickUp
  LABELS = {
    nil => 'in development',
    'Dev Review' => 'in dev review',
    'QA Review' => 'in qa review',
    'merged' => 'ready to deploy'
  }

  USERS = {
    'abelavila140' => 'ABEL',
    'bzuch' => 'BRENT',
    'raywagner88' => 'RAY',
    'xdega' => 'LIAM',
    'RCCAMER' => 'RYAN',
    'bradleyaellis' => 'BRAD',
    'kfindall' => 'KAMI',
    'kinginmn' => 'GRETCHEN',
    'dcoxjr' => 'DOUG',
    'default' => 'ABEL'
  }

  def self.verify_task_id(task_id)
    begin
      response = request(task_id)
      JSON.parse(response.body)
    rescue
      {}
    end
  end

  def self.move_task(task_id, username, status)
    request(task_id, username, status: LABELS[status])
  end

  def self.request(task_id, username='default', body={})
    ::RestClient::Request.execute(
      method: :put,
      url: "https://api.clickup.com/api/v1/task/#{task_id}",
      headers: {
        'Authorization' => token(username),
        'Content-Type' => 'application/json'
      },
      payload: body
    )
  end

  def self.token(username)
    ENV["#{USERS[username]}_CLICK_UP_TOKEN"]
  end
end
