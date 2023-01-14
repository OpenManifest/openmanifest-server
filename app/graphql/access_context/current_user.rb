class AccessContext::CurrentUser
  include Singleton
  attr_accessor :user,
                :dropzone

  # Sets up an access context for a user
  # to check permissions against that user
  # for a specific dropzone
  #
  # @param [User] user
  def self.for(user)
    instance.for_user(user)
  end

  def for_user(user)
    self.user = user
    self
  end

  # Resolve all dropzones this user has access
  # to by checking any dropzones this user is
  # a Staff role at, or any dropzones that are
  # publicly available
  #
  # @return [Dropzones]
  def dropzones
    Dropzone.for(user)
  end

  # Sets the dropzone this access context is for
  #
  # @return [AccessContext::User]
  def at_dropzone(dropzone)
    self.dropzone = dropzone if dropzone.is_a?(Dropzone)
    self.dropzone = Dropzone.find_by(id: dropzone) if dropzone.is_a?(String) || dropzone.is_a?(Integer)
    self
  end

  # Delegates the #can? method to the user
  # if no dropzone is set, or to the dropzone
  # user if a dropzone is set
  #
  # @param [Symbol] permission
  # @return [Boolean]
  def can?(permission)
    return nil unless dropzone_user
    dropzone_user.can?(permission)
  end

  # Gets the dropzone user this access context is for
  #
  # @return [DropzoneUser]
  def dropzone_user
    return nil unless dropzone
    @dropzone_user ||= dropzone.dropzone_users.find_by(user: user)
  end
end
