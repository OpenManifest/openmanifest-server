# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include GraphqlDevise::SetUserByToken
  before_action :set_appsignal_tags

  def index
    render file: "app/views/web-build/index.html", cache: false
  end

  def set_appsignal_tags
    return if Rails.env.test?
    if current_user
      Appsignal.tag_request({
        user_id: current_user&.id,
        name: current_user&.name,
      })
    end
  end
end
