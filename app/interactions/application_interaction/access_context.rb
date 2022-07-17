class ApplicationInteraction::AccessContext
  attr_accessor :dz_user

  def initialize(dropzone_user)
    self.dz_user = dropzone_user
  end

  delegate :can?, :dropzone, :user, to: :dz_user

  # Gets the dropzone user this access context is for
  #
  # @return [DropzoneUser]
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
    new(
      DropzoneUser.find_by(
        { user: user, dropzone: dropzone, dropzone_id: dropzone_id }.compact
      )
    )
  end
end
