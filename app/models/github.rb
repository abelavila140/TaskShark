require 'rest-client'

class Github
  def self.create_pull_request(repo, body={})
    Rails.logger.debug "GOt to the model #{repo}"
    a = ::RestClient::Request.execute(
      method: :post,
      url: "https://api.github.com/repos/#{repo}/pulls",
      headers: {
       #'Authorization': "token #{ENV['GITHUB_TOKEN']}",
        'Authorization': "token 106777b185dc928aaf4e23fb7c8f5cac01e9480e",
        'Content-Type': 'application/json'
      },
      payload: body
    )
    Rails.logger.debug "Im herehre"
    a
  end
end
