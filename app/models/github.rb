class Github
  def self.create_pull_request(repo, body={})
    ::RestClient::Request.execute(
      method: :post,
      url: "https://api.github.com/repos/#{repo}/pulls",
      headers: {
        'Authorization': "token #{ENV['GITHUB_TOKEN']}",
        'Content-Type': 'application/json'
      },
      payload: body.to_json
    )
  end
end
