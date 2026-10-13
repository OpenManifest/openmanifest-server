# frozen_string_literal: true

module Mutations::Setup::Equipment
  # Staff run a member's personal equipment from the office: whoever holds updateUser at an operator where the equipment's
  # owner is a member may create, update and archive the owner's equipment. Members keep full control of their own equipment.
  module OfficeAccess
    private

    # The kind an item is made with: the one asked for, else the first of the operator that keeps it or, for a member's
    # own item, of the operator they joined last
    #
    # @return [EquipmentKind, nil]
    def kind_for(owner:, kind_id:)
      return EquipmentKind.kept.find(kind_id) if kind_id.present?

      operator = owner.is_a?(Operator) ? owner : owner.memberships.kept.order(id: :desc).first&.operator
      operator&.equipment_kinds&.first
    end

    # Applies the attributes of the input to the model: its columns, its kind and the values of the kind's attributes
    # (only those given change; null removes one)
    def assign_equipment(model, attributes, kind: nil)
      attrs = attributes.to_h.except(:packing_card, :kind_id, :attributes, :operator_id, :user_id)
      attrs[:service_due_at] = Time.at(attrs[:service_due_at]) if attrs[:service_due_at]
      attrs[:maintained_at] = Time.at(attrs[:maintained_at]) if attrs[:maintained_at]
      model.assign_attributes(attrs)
      model.kind = kind if kind
      return if attributes[:attributes].nil?

      model.properties = model.properties.merge(attributes[:attributes].to_h.stringify_keys).compact
    end

    # @param [User, nil] owner the user the equipment belongs to
    # @return [Boolean]
    def staff_of_member?(owner)
      return false unless owner

      caller_user = context[:current_resource]
      owner.memberships.kept.pluck(:operator_id).any? do |operator_id|
        caller_user.can?(:updateUser, operator_id: operator_id)
      end
    end
  end
end
