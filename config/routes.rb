# frozen_string_literal: true

Rails.application.routes.draw do
  default_url_options host: ENV.fetch('BACKEND_URL', nil)
  # Not needed with schema plugin
  # mount_graphql_devise_for 'User', at: 'graphql_auth'
  devise_for :users
  mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"

  post "/graphql", to: "graphql#execute"
  get "/graphql", to: "graphql#index"
  get "/.well-known/apple-app-site-association", to: "resource#aasa"

  get "/confirm", to: "application#index"
  get "/", to: "application#index"
  get "/index.html", to: "application#index"
  # get '*path', to: 'application#index', constraints: ->(request) do
  #  !request.xhr? && !request.format.html?
  # end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
