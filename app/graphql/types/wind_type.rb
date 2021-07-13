module Types
  class WindType < Types::BaseObject
    field :altitude, String, null: true
    field :speed, String, null: true
    field :direction, String, null: true
  end
end