# frozen_string_literal: true

# A user becomes a member of an operator. Only public operators can be joined (a moderator can join any), the role is the
# one Membership assigns by default (student, or fun jumper for someone with a certification level or a equipment and body mass), and
# joining twice returns the existing membership. A member who left (or was removed) and joins again gets the same
# membership back, with the default role and without the permissions that were granted to them directly: a removal is not
# undone by joining again.
class Users::JoinOperator < ApplicationInteraction
  record :user
  record :operator

  validate :joinable

  steps :find_or_create_membership

  success do
    next unless @created

    compose(
      ::Activity::CreateEvent,
      access_context: ::ApplicationInteraction::AccessContext.new(@membership),
      level: :info,
      access_level: :admin,
      message: "#{user.name} joined #{operator.name}",
      resource: @membership,
      action: :created,
      operator: operator,
    )
  end

  def find_or_create_membership
    @membership = ::Membership.of(operator, user)
    return @membership if @membership

    @created = true
    previous = ::Membership.discarded.find_by(operator: operator, user: user)
    @membership = previous ? restore(previous) : operator.memberships.create!(user: user)
  end

  private

  def restore(previous)
    default_role = ::Membership.new(operator: operator, user: user).user_role
    previous.transaction do
      previous.user_permissions.destroy_all
      previous.undiscard!
      previous.update!(user_role: default_role)
    end
    previous
  end

  def joinable
    return if user.is_moderator? || operator.state.to_s == "public" || ::Membership.of(operator, user)

    errors.add(:base, "This operator cannot be joined")
  end
end
