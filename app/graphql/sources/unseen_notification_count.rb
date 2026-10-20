# frozen_string_literal: true

# The number of unseen notifications of each member, for all the members of a list in one query
class Sources::UnseenNotificationCount < GraphQL::Dataloader::Source
  def fetch(membership_ids)
    counts = ::Notification.unseen.where(received_by_id: membership_ids).group(:received_by_id).count
    membership_ids.map { |id| counts.fetch(id, 0) }
  end
end
