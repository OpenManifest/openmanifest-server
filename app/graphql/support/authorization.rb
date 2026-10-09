# frozen_string_literal: true

# Tenant checks for resolvers and mutations. A dropzone is a tenant: its data may only be read or changed by people who
# are (still) members of it, and only with the permission their role grants.
#
# The membership is looked up, never created (`DropzoneUser.for` creates one, BUG-005). Platform moderators can see
# every dropzone already (`Dropzone.for`), so they are let through.
module Support::Authorization
  extend ActiveSupport::Concern

  # @return [User, nil]
  def current_user
    context[:current_resource]
  end

  # Raises unless the current user is a member of the dropzone (and has the permission, when one is given)
  #
  # @param [Dropzone] dropzone
  # @param [String, Symbol, nil] permission
  # @return [DropzoneUser, nil] the membership (nil for a moderator without one)
  def authorize_dropzone!(dropzone, permission = nil)
    raise authentication_error unless current_user
    raise forbidden("This dropzone does not exist") unless dropzone

    membership = DropzoneUser.kept.find_by(dropzone_id: dropzone.id, user_id: current_user.id)
    if membership.nil?
      return nil if current_user.is_moderator?
      raise forbidden("You are not a member of this dropzone")
    end
    raise forbidden("You do not have permission to do that (#{permission})") if permission && !membership.can?(permission)

    membership
  end

  # Same as {#authorize_dropzone!} for the dropzone a record belongs to
  #
  # @param [ApplicationRecord] record a record that has (or reaches) a dropzone
  # @param [String, Symbol, nil] permission
  def authorize_record!(record, permission = nil)
    raise forbidden("This record does not exist") unless record

    authorize_dropzone!(dropzone_of(record), permission)
  end

  private

  def dropzone_of(record)
    return record if record.is_a?(Dropzone)
    return record.dropzone if record.respond_to?(:dropzone) && record.dropzone
    return record.load.dropzone if record.respond_to?(:load) && record.load
    return record.ticket_type.dropzone if record.respond_to?(:ticket_type) && record.ticket_type

    nil
  end

  def forbidden(message)
    GraphQL::ExecutionError.new(message, extensions: { code: "FORBIDDEN" })
  end

  def authentication_error
    GraphQL::ExecutionError.new("You need to be logged in", extensions: { code: "AUTHENTICATION_ERROR" })
  end
end
