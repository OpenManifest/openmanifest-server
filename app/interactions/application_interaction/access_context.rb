# frozen_string_literal: true

# Who performs an interaction, and where. Usually that is a member of the dropzone (the subject); a platform moderator
# who is not a member has no membership, only a user and a dropzone, and no permissions of their own.
class ApplicationInteraction::AccessContext
  attr_accessor :dz_user

  # @param [DropzoneUser, nil] dropzone_user
  # @param [User, nil] user the acting user when there is no membership
  # @param [Dropzone, nil] dropzone the dropzone when there is no membership
  def initialize(dropzone_user, user: nil, dropzone: nil)
    self.dz_user = dropzone_user
    @user = user
    @dropzone = dropzone
  end

  def user
    dz_user&.user || @user
  end

  def dropzone
    dz_user&.dropzone || @dropzone
  end

  def can?(permission)
    return false unless dz_user

    dz_user.can?(permission)
  end

  # Gets the dropzone user this access context is for
  #
  # @return [DropzoneUser, nil]
  def subject
    dz_user
  end

  # Create an access context for a user by finding the DropzoneUser
  # for the given dropzone
  #
  # @param [User] user
  # @param [Dropzone] dropzone
  # @param [Integer] dropzone_id
  # @return [AccessContext]
  def self.for(user, dropzone: nil, dropzone_id: nil)
    membership = DropzoneUser.find_by(
      { user: user, dropzone: dropzone, dropzone_id: dropzone_id }.compact
    )
    new(membership, user: user, dropzone: dropzone || (dropzone_id && Dropzone.find_by(id: dropzone_id)))
  end
end
