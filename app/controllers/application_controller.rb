# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include GraphqlDevise::Concerns::SetUserByToken
end
