# frozen_string_literal: true

class Resolvers::JumpTypes < Resolvers::Base
  description "Get all jump types"
  type [Types::JumpTypeType], null: false
  argument :dropzone_users, [Int], required: false,
           prepare: -> (value, ctx) { DropzoneUser.where(id: value) }

  def resolve(dropzone_users: nil, lookahead: nil)
    if dropzone_users
      JumpType.allowed_for(dropzone_users)
    else
      JumpType.order(name: :asc)
    end
  end

  def authenticated?
    true
  end
end
