# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include GraphqlDevise::Concerns::SetUserByToken
  before_action :set_appsignal_tags

  def index
    render file: "app/views/web-build/index.html", cache: false
  end

  def set_appsignal_tags
    return if Rails.env.test?
    if current_resource
      tags.merge!(
        user_id: current_resource&.id,
        name: current_resource&.name,
      )
    end
    Appsignal.tag_request(tags)
  end
end
