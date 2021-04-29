# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include GraphqlDevise::Concerns::SetUserByToken

  def index
    render file: 'public/index.html'
  end
end
