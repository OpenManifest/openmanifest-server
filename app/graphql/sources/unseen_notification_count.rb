# frozen_string_literal: true

# The number of unseen notifications of each member, for all the members of a list in one query
class Sources::UnseenNotificationCount < GraphQL::Dataloader::Source
  def fetch(dropzone_user_ids)
    counts = ::Notification.unseen.where(received_by_id: dropzone_user_ids).group(:received_by_id).count
    dropzone_user_ids.map { |id| counts.fetch(id, 0) }
  end
end
