# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include GraphqlDevise::Concerns::SetUserByToken

  def index
    render file: 'app/views/web-build/index.html', cache: false
  end
end
