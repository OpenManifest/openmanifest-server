# frozen_string_literal: true

class Resolvers::Access::CurrentUser < Resolvers::Base
  type Types::UserType, null: true
  description "Currently authenticated user"

  def resolve
    return nil unless context[:current_resource]
    query = User
    query = query.includes(:rigs) if lookahead.selects?(:rigs)
    if lookahead.selects?(:dropzone_users)
      if lookahead.selection(:dropzone_users).selects?(:dropzone)
        query = query.includes(dropzone_users: :dropzone)
      else
        query = query.includes(:dropzone_users)
      end
    end

    if lookahead.selects?(:user_federations)
      subselections = []
      subselections << :license if lookahead.selection(:user_federations).selects?(:license)
      subselections << :federation if lookahead.selection(:user_federations).selects?(:federation)

      if subselections.empty?
        query = query.includes(:user_federations)
      else
        query = query.includes(user_federations: subselections)
      end
    end

    query.order(name: :asc)
  end
end
