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
    'mclark-syc' => 'MARY',
    'default' => 'ABEL'
  }

  def self.verify_task_id(task_id)
    begin
      response = request(:get, task_id)
      JSON.parse(response.body)
    rescue
      {}
    end
  end

  def self.move_task(task_id, username, status)
    request(:put, task_id, username, status: LABELS[status])
  end

  def self.attach_github_url(task_id, username, url)
    request(:post, "#{task_id}/field/#{field_id}", username, value: url)
  end

  def self.request(method, path, username='default', body={})
    ::RestClient::Request.execute(
      method: method,
      url: "https://api.clickup.com/api/v2/task/#{path}",
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

  def self.field_id
    "0233f3a9-3780-4357-95a9-b305216fee84"
  end
end
