class ApplicationController < ActionController::Base
  include GraphqlDevise::Concerns::SetUserByToken
end
