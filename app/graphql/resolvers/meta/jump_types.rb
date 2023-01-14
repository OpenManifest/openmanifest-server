# frozen_string_literal: true

class Resolvers::Meta::JumpTypes < Resolvers::Base
  description "Get all jump types"
  type [Types::Meta::JumpType], null: false
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
