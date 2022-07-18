class Types::Admin::StatisticsType < Types::BaseObject
  field :total_user_count, Integer, null: false
  field :active_user_count, Integer, null: false
  field :inactive_user_count, Integer, null: false
  field :gca_count, Integer, null: false
  field :dzso_count, Integer, null: false
  field :pilot_count, Integer, null: false
  field :rig_inspector_count, Integer, null: false

  field :loads_count, Integer, null: false
  field :cancelled_loads_count, Integer, null: false
  field :finalized_loads_count, Integer, null: false

  field :revenue_cents_count, Integer, null: false
end
