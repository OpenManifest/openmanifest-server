# frozen_string_literal: true

class Types::Admin::StatisticsType < Types::BaseObject
  field :total_user_count, Integer, null: false, method: :users_count
  field :active_user_count, Integer, null: false
  def active_user_count
    object.dropzone_users.kept.count
  end
  field :inactive_user_count, Integer, null: false
  def inactive_user_count
    object.dropzone_users.discarded.count
  end
  field :gca_count, Integer, null: false
  def gca_count
    object.dropzone_users.with_acting_permission(:actAsGCA).count
  end
  field :dzso_count, Integer, null: false
  def dzso_count
    object.dropzone_users.with_acting_permission(:actAsDZSO).count
  end
  field :pilot_count, Integer, null: false
  def pilot_count
    object.dropzone_users.with_acting_permission(:actAsPilot).count
  end
  field :rig_inspector_count, Integer, null: false
  def rig_inspector_count
    object.dropzone_users.with_acting_permission(:actAsRigInspector).count
  end
  field :loads_count, Integer, null: false
  def loads_count
    object.loads.count
  end
  field :cancelled_loads_count, Integer, null: false
  def cancelled_loads_count
    object.loads.cancelled.count
  end
  field :finalized_loads_count, Integer, null: false
  def finalized_loads_count
    object.loads.landed.count
  end

  field :revenue_cents_count, Integer, null: false
  def revenue_cents_count
    object.sales.where(state: :completed).sum(:amount)
  end

  field :load_count_by_day, Types::Admin::StatisticsByDateType, null: true,
        description: "Get the number of loads dispatched per day"
  def load_count_by_day
    object.loads.landed.group("date_trunc('day', loads.dispatch_at)").count.map do |date, count|
      { date: date, count: count }
    end
  end
end
