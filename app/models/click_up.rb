require 'rest-client'

class ClickUp
  STATUSES = {
    'backlog' => 0,
    'in development' => 1,
    'in dev review' => 2,
    'in qa review' => 3,
    'ready to deploy' => 4
  }

  LABELS = {
    nil => 'in development',
    'backlog' => 'backlog',
    'development' => 'in development',
    'Dev Review' => 'in dev review',
    'QA Review' => 'in qa review',
    'merged' => 'ready to deploy',
    'closed' => 'Closed'
  }

  USERS = {
    'abelavila140' => 'ABEL',
    'bzuch' => 'BRENT',
    'raywagner88' => 'RAY',
    'kfindall' => 'KAMI',
    'kinginmn' => 'GRETCHEN',
    'dcoxjr' => 'DOUG',
    'mclark-syc' => 'MARY',
    'BrettAshEllis' => 'BRETT',
    'ThomMcCoppin' => 'THOMAS',
    'default' => 'ABEL'
  }

  def self.verify_task_id(task_id)
    response = request(:get, "task/#{task_id}")
    JSON.parse(response.body)
  rescue
    {}
  end

  def self.subtasks(list_id, task_id)
    response = request(:get, "list/#{list_id}/task?parent=#{task_id}")
    Rails.logger.debug "LIST: #{list_id}"
    JSON.parse(response.body)
  rescue
    {}
  end

  def self.move_task(task_id, username, status)
    request(:put, "task/#{task_id}", username, status: LABELS[status])
  end

  def self.attach_github_url(task_id, username, url)
    request(:post, "task/#{task_id}/field/#{field_id}", username, value: url)
  end

  def self.request(method, path, username='default', body={})
    ::RestClient::Request.execute(
      method: method,
      url: "https://api.clickup.com/api/v2/#{path}",
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
