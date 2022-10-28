Rails.application.routes.draw do
  resources :tasks
  mount GitHooks::Engine, at: '/git_hooks'
end
