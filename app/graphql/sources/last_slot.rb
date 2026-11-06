# frozen_string_literal: true

# The slot each member last flew, for all the members of a list in one query: their most recent slot on a load that has
# left or landed (UB.3). A member who has not flown has none.
class Sources::LastSlot < GraphQL::Dataloader::Source
  def fetch(membership_ids)
    slots = ::Slot.joins(:load).
      where(membership_id: membership_ids, loads: { state: ::Load.states.values_at("departed", "completed"), discarded_at: nil }).
      select("DISTINCT ON (slots.membership_id) slots.*").
      order(Arel.sql("slots.membership_id, COALESCE(loads.completed_at, loads.departed_at, loads.updated_at) DESC, slots.id DESC")).
      index_by(&:membership_id)
    membership_ids.map { |id| slots[id] }
  end
end
