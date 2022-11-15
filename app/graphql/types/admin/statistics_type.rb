# frozen_string_literal: true

class Types::Admin::StatisticsType < Types::BaseObject
  field :id, ID, null: false

  field :active_user_count, Integer, null: false

  field :inactive_user_count, Integer, null: false

  field :gca_count, Integer, null: false

  field :dzso_count, Integer, null: false

  field :pilot_count, Integer, null: false

  field :rig_inspector_count, Integer, null: false

  field :loads_count, Integer, null: false do
    argument :time_range, Types::Input::TimeRangeInput, required: false
  end

  field :slots_count, Integer, null: false do
    argument :time_range, Types::Input::TimeRangeInput, required: false
  end

  field :cancelled_loads_count, Integer, null: false do
    argument :time_range, Types::Input::TimeRangeInput, required: false
  end

  field :finalized_loads_count, Integer, null: false do
    argument :time_range, Types::Input::TimeRangeInput, required: false
  end

  field :revenue_cents_count, Integer, null: false do
    argument :time_range, Types::Input::TimeRangeInput, required: false
  end

  field :load_count_by_day, [Types::Admin::StatisticsByDateType], null: true,
                                                                  description: "Get the number of loads dispatched per day" do
    argument :time_range, Types::Input::TimeRangeInput, required: false
  end

  field :slots_by_jump_type, [Types::Admin::StatisticsByNameType], null: true,
                                                                   description: "Get the number of slots by jump type" do
    argument :time_range, Types::Input::TimeRangeInput, required: false
  end

  field :total_user_count, Integer, null: false
  def total_user_count
    object.dropzone_users.count
  end

  def active_user_count
    object.dropzone_users.kept.count
  end

  def inactive_user_count
    object.dropzone_users.discarded.count
  end

  def gca_count
    object.dropzone_users.with_acting_permission(:actAsGCA).count
  end

  def dzso_count
    object.dropzone_users.with_acting_permission(:actAsDZSO).count
  end

  def pilot_count
    object.dropzone_users.with_acting_permission(:actAsPilot).count
  end

  def rig_inspector_count
    object.dropzone_users.with_acting_permission(:actAsRigInspector).count
  end

  def loads_count(time_range: nil)
    query = object.loads
    query = query.where(dispatch_at: time_range.start_time..time_range.end_time) if time_range
    query.count
  end

  def slots_count(time_range: nil)
    query = object.loads
    query = query.where(dispatch_at: time_range.start_time..time_range.end_time) if time_range
    Slot.where(load: query).count
  end

  def cancelled_loads_count(time_range: nil)
    query = object.loads.cancelled
    query = query.where(dispatch_at: time_range.start_time..time_range.end_time) if time_range
    query.count
  end

  def finalized_loads_count(time_range: nil)
    query = object.loads.landed
    query = query.where(dispatch_at: time_range.start_time..time_range.end_time) if time_range
    query.count
  end

  def revenue_cents_count(time_range: nil)
    query = object.sales.where(state: :completed)
    query = query.where(created_at: time_range.start_time..time_range.end_time) if time_range
    query.sum(:amount)
  end

  def load_count_by_day(time_range: nil)
    query = object.loads.landed
    query = query.where(dispatch_at: time_range.start_time..time_range.end_time) if time_range
    query.group("date_trunc('day', loads.dispatch_at)").count.map do |date, count|
      { date: date, count: count }
    end
  end

  def slots_by_jump_type(time_range: nil)
    query = object.loads.landed
    query = query.where(dispatch_at: time_range.start_time..time_range.end_time) if time_range
    Slot.joins(:jump_type).where(load: query).group(:'jump_types.slug').having("COUNT(slots.id) > 1").count.map do |name, count|
      { name: name, count: count }
    end
  end
end
