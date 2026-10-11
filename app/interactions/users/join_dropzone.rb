# frozen_string_literal: true

# A user becomes a member of a dropzone. Only public dropzones can be joined (a moderator can join any), the role is the
# one DropzoneUser assigns by default (student, or fun jumper for someone with a license or a rig and exit weight), and
# joining twice returns the existing membership. A member who left (or was removed) and joins again gets the same
# membership back, with the default role and without the permissions that were granted to them directly: a removal is not
# undone by joining again.
class Users::JoinDropzone < ApplicationInteraction
  record :user
  record :dropzone

  validate :joinable

  steps :find_or_create_membership

  success do
    next unless @created

    compose(
      ::Activity::CreateEvent,
      access_context: ::ApplicationInteraction::AccessContext.new(@membership),
      level: :info,
      access_level: :admin,
      message: "#{user.name} joined #{dropzone.name}",
      resource: @membership,
      action: :created,
      dropzone: dropzone,
    )
  end

  def find_or_create_membership
    @membership = ::DropzoneUser.membership(dropzone, user)
    return @membership if @membership

    @created = true
    previous = ::DropzoneUser.discarded.find_by(dropzone: dropzone, user: user)
    @membership = previous ? restore(previous) : dropzone.dropzone_users.create!(user: user)
  end

  private

  def restore(previous)
    default_role = ::DropzoneUser.new(dropzone: dropzone, user: user).user_role
    previous.transaction do
      previous.user_permissions.destroy_all
      previous.undiscard!
      previous.update!(user_role: default_role)
    end
    previous
  end

  def joinable
    return if user.is_moderator? || dropzone.state.to_s == "public" || ::DropzoneUser.membership(dropzone, user)

    errors.add(:base, "This dropzone cannot be joined")
  end
end
