# frozen_string_literal: true

module Types::Dropzone::Weather
  class Wind < Types::Base::Object
    field :altitude, String, null: true
    field :speed, String, null: true
    field :direction, String, null: true
    field :temperature, String, null: true
  end
end
