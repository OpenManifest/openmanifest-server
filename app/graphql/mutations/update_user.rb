# frozen_string_literal: true

module Mutations
  class UpdateUser < Mutations::BaseMutation
    field :user, Types::UserType, null: true

    argument :attributes, Types::Input::UserInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = context[:current_user]
      model.attributes = attributes.to_h


      if model.save
        { user: model }
      else
        { errors: model.errors.full_messages }
      end
    end

    def find_or_build_model(id)
      if id
        User.find(id)
      else
        User.new
      end
    end
  end
end
