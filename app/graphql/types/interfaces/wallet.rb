# frozen_string_literal: true

module Types::Interfaces
  module Wallet
    include Types::Base::Interface

    field :wallet_id, ID, null: false
    def wallet_id
      object.to_gid_param
    end

    field :orders, Types::Payments::Order.connection_type, null: true do
      argument :start_date, Integer, required: false
    end
    def orders(start_date: nil)
      is_self = context[:current_resource].id == object.user.id if object.is_a?(DropzoneUser)
      is_self ||= context[:current_resource].can?(:readUserTransactions, dropzone_id: object.id) if object.is_a?(Dropzone)

      can_see_others = context[:current_resource].can?("readUserTransactions", dropzone_id: object.try(:dropzone_id) || object.id)
      return [] unless can_see_others || is_self
      query = Order.where(buyer: object).or(Order.where(seller: object)).where.not(state: :cancelled)
      query.where!("created_at > ?", Time.at(start_date)) if start_date
      query.order(created_at: :desc)
    end

    field :purchases, Types::Payments::Order.connection_type, null: true
    def purchases
      is_self = context[:current_resource].id == object.user.id
      can_see_others = context[:current_resource].can?("readUserTransactions", dropzone_id: object.dropzone_id)

      if can_see_others || is_self
        object.purchases.order(created_at: :desc)
      else
        []
      end
    end

    field :sales, Types::Payments::Order.connection_type, null: true
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
          ::DropzoneUser => Types::Users::DropzoneUser,
          ::Dropzone => Types::DropzoneType,
        }[object.class]
      end
    end
  end
end
