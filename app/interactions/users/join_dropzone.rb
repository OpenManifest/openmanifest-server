# frozen_string_literal: true

# A user becomes a member of a dropzone. Only public dropzones can be joined (a moderator can join any), the role is the
# one DropzoneUser assigns by default (student, or fun jumper for someone with a license or a rig and exit weight), and
# joining twice returns the existing membership.
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
    @membership = dropzone.dropzone_users.create!(user: user)
  end

  private

  def joinable
    return if user.is_moderator? || dropzone.state.to_s == "public" || ::DropzoneUser.membership(dropzone, user)

    errors.add(:base, "This dropzone cannot be joined")
  end
end
