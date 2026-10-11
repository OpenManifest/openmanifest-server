# frozen_string_literal: true

module Mutations::Setup::Operators
  class UpdateOperator < Mutations::BaseMutation
    field :operator, Types::OperatorType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::OperatorInput, required: true
    argument :id, Int, required: true

    def resolve(attributes:, id:)
      model = Operator.find(id)
      attrs = attributes.to_h.except(:banner)
      Support::ImageUpload.attach(model.banner, attributes[:banner], name: "banner") if attributes[:banner]
      # The state machine's event has the name of the request_publication column and takes over its accessors, so the
      # request is made through the event; a private operator moves to in_review and the moderators are told, once
      if attrs.delete(:request_publication) && model.state == "private"
        announce_publication_request(model)
        model.fire_state_event(:request_publication)
        model[:request_publication] = true
      end
      model.update!(attrs)

      {
        operator: model,
        errors: nil,
        field_errors: nil,
      }
    rescue Support::ImageUpload::Invalid => e
      { operator: nil, field_errors: [{ field: "banner", message: e.message }], errors: [e.message] }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        operator: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        operator: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        operator: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    # The platform's moderators are told, in the operators they are members of (a notification belongs to a member), and
    # the operator's own log shows the request
    def announce_publication_request(model)
      moderators = Membership.kept.where(operator: model, user: User.where(moderation_role: %w(moderator administrator)))
      sender = Membership.of(model, context[:current_resource])
      moderators.find_each do |moderator|
        Notification.create!(
          received_by: moderator,
          message: "Operator #{model.name} has requested publication",
          notification_type: :publication_requested,
          resource: model,
          sent_by: sender
        )
      end

      Activity::Event.create!(
        operator: model, resource: model, action: :updated, level: :info, access_level: :admin, created_by: sender,
        message: "#{context[:current_resource].name} requested publication of #{model.name}"
      )
    end

    def authorized?(id: nil, attributes: nil)
      operator = Operator.find(id)

      if attributes[:is_public] && operator.is_public != attributes[:is_public] && (User.moderation_roles[context[:current_resource].moderation_role] < User.moderation_roles["moderator"])
        return false, {
          errors: [
            "You cant modify the publication state of this operator",
          ],
        }
      end

      if context[:current_resource].can?(
        "updateOperator",
        operator_id: id
      )
        return true
      end
      [
        false, {
          errors: [
            "You don't have permissions to edit this operator",
          ],
        },
      ]
    end
  end
end
