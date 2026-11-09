# frozen_string_literal: true

# Who performs an interaction, and where. Usually that is a member of the operator (the subject); a platform moderator
# who is not a member has no membership, only a user and an operator, and no permissions of their own.
class ApplicationInteraction::AccessContext
  attr_accessor :dz_user

  # @param [Membership, nil] membership
  # @param [User, nil] user the acting user when there is no membership
  # @param [Operator, nil] operator the operator when there is no membership
  def initialize(membership, user: nil, operator: nil)
    self.dz_user = membership
    @user = user
    @operator = operator
  end

  def user
    dz_user&.user || @user
  end

  def operator
    dz_user&.operator || @operator
  end

  def can?(permission)
    return false unless dz_user

    dz_user.can?(permission)
  end

  # Gets the operator user this access context is for
  #
  # @return [Membership, nil]
  def subject
    dz_user
  end

  # Create an access context for a user by finding the Membership
  # for the given operator
  #
  # @param [User] user
  # @param [Operator] operator
  # @param [Integer] operator_id
  # @return [AccessContext]
  def self.for(user, operator: nil, operator_id: nil)
    membership = Membership.find_by(
      { user: user, operator: operator, operator_id: operator_id }.compact
    )
    new(membership, user: user, operator: operator || (operator_id && Operator.find_by(id: operator_id)))
  end
end
