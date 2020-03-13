class ApplicationController < ActionController::API
  before_action :require_pull_request!

  private
    def require_pull_request!
      event_type = request.headers['X-GitHub-Event'].to_sym
      head :no_content unless event_type == :pull_request
    end
end
