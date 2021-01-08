class Github
  USERS = {
    'abelavila140' => 'ABEL',
    'bzuch' => 'BRENT',
    'raywagner88' => 'RAY',
    'suttonal' => 'AMY',
    'bradleyaellis' => 'BRAD'
  }

  def self.create_pull_request(repo, username, body={})
    Rails.logger.info "_______________"
    Rails.logger.info repo
    Rails.logger.info username
    Rails.logger.info body.inspect
    Rails.logger.info "_______________"

    a = ::RestClient::Request.execute(
      method: :post,
      url: "https://api.github.com/repos/#{repo}/pulls",
      headers: {
        'Authorization': "token #{token(username)}",
        'Content-Type': 'application/json'
      },
      payload: body.to_json
    )
    Rails.logger.info JSON.parse(a).inspect
    a
  end

  def self.token(username)
    ENV["#{USERS[username]}_GITHUB_TOKEN"]
  end
end
