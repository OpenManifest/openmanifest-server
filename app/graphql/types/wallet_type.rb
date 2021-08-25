# frozen_string_literal: true

module Types
  module WalletType
    include Types::BaseInterface

    field :orders, Types::OrderType.connection_type, null: true
    def orders
      is_self = context[:current_resource].id == object.user.id
      can_see_others = context[:current_resource].can?("readUserTransactions", dropzone_id: object.dropzone_id)


      if can_see_others || is_self
        Order.where(buyer: object).or(Order.where(seller: object)).where.not(state: :cancelled).order(created_at: :desc)
      else
        []
      end
    end

    field :purchases, Types::OrderType.connection_type, null: true
    def purchases
      is_self = context[:current_resource].id == object.user.id
      can_see_others = context[:current_resource].can?("readUserTransactions", dropzone_id: object.dropzone_id)


      if can_see_others || is_self
        object.purchases.order(created_at: :desc)
      else
        []
      end
    end

    field :sales, Types::OrderType.connection_type, null: true
    def sales
      is_self = context[:current_resource].id == object.user.id
      can_see_others = context[:current_resource].can?("readUserTransactions", dropzone_id: object.dropzone_id)


      if can_see_others || is_self
        object.purchases.order(created_at: :desc)
      else
        []
      end
    end

    definition_methods do
      # Determine what object type to use for `object`
      def resolve_type(object, context)
        {
          DropzoneUser => Types::DropzoneUserType,
          Dropzone => Types::DropzoneType
        }[object.class]
      end
    end
  end
end
