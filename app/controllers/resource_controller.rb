# frozen_string_literal: true

class ResourceController < ApplicationController

  def aasa
    render json: File.read("public/apple-app-site-association.json")
  end
end
