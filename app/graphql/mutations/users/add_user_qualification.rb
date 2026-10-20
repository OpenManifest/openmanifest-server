# frozen_string_literal: true

module Mutations::Users
  class AddUserQualification < Mutations::BaseMutation
    field :user_qualification, Types::Users::UserQualification, null: true

    argument :qualification_id, GraphQL::Types::ID, required: true
    argument :number, String, required: false, description: "The number on the qualification"
    argument :expires_at, GraphQL::Types::ISO8601DateTime, required: false, description: "Leave empty for a qualification that does not expire"

    def resolve(qualification_id:, number: nil, expires_at: nil)
      qualification = ::Qualification.find_by(id: qualification_id)
      return { user_qualification: nil, field_errors: nil, errors: ["Qualification not found"] } unless qualification

      mutate(
        ::Certifications::AddQualification,
        :user_qualification,
        user: context[:current_resource],
        qualification: qualification,
        number: number,
        expires_at: expires_at&.to_datetime
      )
    end

    def authorized?(**)
      context[:current_resource].present?
    end
  end
end
