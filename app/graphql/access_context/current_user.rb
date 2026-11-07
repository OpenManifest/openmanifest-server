# The permissions of one user, optionally at one operator. An instance belongs to a single request (or cable message):
# never keep one in a constant, a class variable or anything else that outlives it.
class AccessContext::CurrentUser
  attr_reader :user,
              :operator

  # Sets up an access context for a user
  # to check permissions against that user
  # for a specific operator
  #
  # @param [User] user
  def self.for(user)
    new(user)
  end

  def initialize(user)
    @user = user
  end

  # Resolve all operators this user has access
  # to by checking any operators this user is
  # a Staff role at, or any operators that are
  # publicly available
  #
  # @return [Operators]
  def operators
    Operator.for(user)
  end

  # Sets the operator this access context is for
  #
  # @return [AccessContext::User]
  def at_operator(operator)
    resolved = if operator.is_a?(Operator)
                 operator
               elsif operator.is_a?(String) || operator.is_a?(Integer)
                 Operator.find_by(id: operator)
               else
                 @operator
               end

    # The membership belongs to the operator it was looked up at
    @membership = nil unless resolved == @operator
    @operator = resolved
    self
  end

  # Delegates the #can? method to the user
  # if no operator is set, or to the operator
  # user if an operator is set
  #
  # @param [Symbol] permission
  # @return [Boolean]
  def can?(permission)
    return nil unless membership
    membership.can?(permission)
  end

  # Gets the operator user this access context is for
  #
  # @return [Membership]
  def membership
    return nil unless operator
    @membership ||= operator.memberships.find_by(user: user)
  end
end
