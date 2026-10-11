# The permissions of one user, optionally at one dropzone. An instance belongs to a single request (or cable message):
# never keep one in a constant, a class variable or anything else that outlives it.
class AccessContext::CurrentUser
  attr_reader :user,
              :dropzone

  # Sets up an access context for a user
  # to check permissions against that user
  # for a specific dropzone
  #
  # @param [User] user
  def self.for(user)
    new(user)
  end

  def initialize(user)
    @user = user
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
    resolved = if dropzone.is_a?(Dropzone)
                 dropzone
               elsif dropzone.is_a?(String) || dropzone.is_a?(Integer)
                 Dropzone.find_by(id: dropzone)
               else
                 @dropzone
               end

    # The membership belongs to the dropzone it was looked up at
    @dropzone_user = nil unless resolved == @dropzone
    @dropzone = resolved
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
