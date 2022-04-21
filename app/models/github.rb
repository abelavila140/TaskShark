class Github
  USERS = {
    'abelavila140' => 'ABEL',
    'bzuch' => 'BRENT',
    'raywagner88' => 'RAY',
    'kfindall' => 'KAMI',
    'BrettAshEllis' => 'BRETT',
    'ThomMcCoppin' => 'THOMAS'
  }

  def self.create_pull_request(repo, username, body={})
    ::RestClient::Request.execute(
      method: :post,
      url: "https://api.github.com/repos/#{repo}/pulls",
      headers: {
        'Authorization': "token #{token(username)}",
        'Content-Type': 'application/json'
      },
      payload: body.to_json
    )
  end

  def self.update_pull_request(id, repo, username, body={})
    ::RestClient::Request.execute(
      method: :patch,
      url: "https://api.github.com/repos/#{repo}/pulls/#{id}",
      headers: {
        'Authorization': "token #{token(username)}",
        'Content-Type': 'application/json'
      },
      payload: body.to_json
    )
  end

  def self.token(username)
    ENV["#{USERS[username]}_GITHUB_TOKEN"]
  end
end
