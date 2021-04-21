# frozen_string_literal: true

Rails.application.routes.draw do
  # Not needed with schema plugin
  # mount_graphql_devise_for 'User', at: 'graphql_auth'

  namespace :manage do
    resources :federations
    resources :planes

    resources :ticket_types
    resources :loads
    resources :dropzone_users
    resources :licenses
    resources :ticket_type_extras
    resources :slots
    resources :rigs
    resources :slot_extras
    resources :licensed_jump_types
    resources :jump_types
    resources :dropzones
    resources :extras
    resources :packs
    resources :users

    root to: "dropzones#index"
  end
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  post "/graphql", to: "graphql#execute"
  get "/graphql", to: "graphql#index"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
