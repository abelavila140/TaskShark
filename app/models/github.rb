require 'rest-client'

class Github
  def self.create_pull_request(repo, body={})
    Rails.logger.debug "GOt to the model #{repo}"
    a = ::RestClient::Request.execute(
      method: :post,
      url: "https://api.github.com/repos/#{repo}/pulls",
      headers: {
       #'Authorization': "token #{ENV['GITHUB_TOKEN']}",
        'Authorization': "token 7aead624f2e6823be7617cc26f5372b13f2c6b6f",
        'Content-Type': 'application/json'
      },
      payload: body
    )
    Rails.logger.debug "Im herehre"
    a
  end
end
