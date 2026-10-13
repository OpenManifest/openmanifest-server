# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261009110000_add_unique_index_to_dropzone_users_on_user_and_dropzone")
require Rails.root.join("db/migrate/20261009110100_add_dropzone_and_load_date_to_loads")
require Rails.root.join("db/migrate/20261009110200_add_unique_order_numbers_and_indexes")
require Rails.root.join("db/migrate/20261009130000_add_date_to_weather_conditions_and_decimal_miles")
require Rails.root.join("db/migrate/20261009150000_add_cents_columns_for_money")
require Rails.root.join("db/migrate/20261011130000_drop_legacy_columns")
require Rails.root.join("db/migrate/20261011140000_rename_dropzone_to_operator")
require Rails.root.join("db/migrate/20261011150000_rename_aviation_names_to_generic")
require Rails.root.join("db/migrate/20261012110000_create_load_vehicles")
require Rails.root.join("db/migrate/20261012120000_create_crew_roles")

# The data steps of the P6.16 migrations, run against rows that the unique indexes would not let exist: the example's
# transaction drops the index (PostgreSQL DDL is transactional) and rolls everything back at the end.
#
# The steps were written for the schema of their time, before P7.2 dropped the old money columns, P7.3 renamed the
# tenant, P7.5 the aviation names and P7.9 the vehicle of a load. Each example builds its rows with today's models, goes back to that schema inside `with_legacy_schema` (the
# migrations are reversible, so the rows come along), runs the step and returns to today's schema for the assertions.
RSpec.describe "P6.16 constraint migrations" do
  let(:connection) { ActiveRecord::Base.connection }
  let(:operator) { create(:operator) }
  let(:vehicle) { create(:vehicle, operator: operator) }

  def run_quietly(migration, step)
    ActiveRecord::Migration.suppress_messages { migration.public_send(step) }
  end

  def reset_models
    [Operator, Membership, TicketType, Extra, Order, Transaction, Vehicle, Load, Slot, WeatherCondition].each(&:reset_column_information)
  end

  def with_legacy_schema
    ActiveRecord::Migration.suppress_messages do
      GeneraliseEquipment.new.migrate(:down)
      GeneraliseCertifications.new.migrate(:down)
      CreateCrewRoles.new.migrate(:down)
      CreateLoadVehicles.new.migrate(:down)
      RenameAviationNamesToGeneric.new.migrate(:down)
      RenameDropzoneToOperator.new.migrate(:down)
      DropLegacyColumns.new.migrate(:down)
    end
    reset_models
    yield
  ensure
    ActiveRecord::Migration.suppress_messages do
      DropLegacyColumns.new.migrate(:up)
      RenameDropzoneToOperator.new.migrate(:up)
      RenameAviationNamesToGeneric.new.migrate(:up)
      CreateLoadVehicles.new.migrate(:up)
      CreateCrewRoles.new.migrate(:up)
      GeneraliseCertifications.new.migrate(:up)
      GeneraliseEquipment.new.migrate(:up)
    end
    reset_models
  end

  # Rows as they were before: the legacy tables and columns, by SQL
  def legacy_update(table, id, **columns)
    sets = columns.map { |column, value| "#{connection.quote_column_name(column)} = #{connection.quote(value)}" }.join(", ")
    connection.update("UPDATE #{table} SET #{sets} WHERE id = #{Integer(id)}")
  end

  def legacy_value(table, column, id)
    connection.select_value("SELECT #{column} FROM #{table} WHERE id = #{Integer(id)}")
  end

  describe AddUniqueIndexToDropzoneUsersOnUserAndDropzone do
    let(:migration) { described_class.new }
    let(:user) { create(:user) }
    let!(:oldest) { create(:membership, operator: operator, user: user, credits: 100, load_count: 5) }

    before { connection.remove_index :memberships, name: "index_memberships_on_user_id_and_operator_id" }

    def duplicate_membership(**attrs)
      Membership.new(operator: operator, user: user, user_role: oldest.user_role, certification_level: oldest.certification_level, **attrs).tap { |member| member.save!(validate: false) }
    end

    it "merges the duplicates into the oldest membership" do
      duplicate = duplicate_membership(load_count: 2)
      legacy_credits = nil

      with_legacy_schema do
        legacy_update(:dropzone_users, oldest.id, credits: 100)
        legacy_update(:dropzone_users, duplicate.id, credits: 40)
        run_quietly(migration, :merge_duplicate_memberships)
        # The migration of that time knows the old column of units only
        legacy_credits = legacy_value(:dropzone_users, :credits, oldest.id)
      end

      expect(Membership.where(id: duplicate.id)).to be_empty
      expect(oldest.reload).to have_attributes(load_count: 7)
      expect(legacy_credits).to eq(140)
      expect(Membership.where(user: user, operator: operator).count).to eq(1)
    end

    it "moves what pointed at a duplicate to the oldest membership" do
      duplicate = duplicate_membership
      vehicle_load = create(:load, vehicle: vehicle, gca: duplicate, pilot: duplicate)
      slot = Slot.new(load: vehicle_load, membership: duplicate, created_by: duplicate, body_mass_kg: 80,
                      ticket_type: create(:ticket_type, operator: operator), activity_type: ActivityType.first).tap { |new_slot| new_slot.save!(validate: false) }
      order = create(:order, operator: operator, seller: operator, buyer: duplicate)
      duplicate.grant!(:actAsPilot)

      with_legacy_schema { run_quietly(migration, :merge_duplicate_memberships) }

      expect(vehicle_load.reload).to have_attributes(gca: oldest, pilot: oldest)
      expect(slot.reload).to have_attributes(membership_id: oldest.id, created_by_id: oldest.id)
      expect(order.reload.buyer).to eq(oldest)
      expect(oldest.reload.permissions.pluck(:name)).to include("actAsPilot")
    end

    it "keeps one slot where several memberships were on the same load, and fixes the counters" do
      duplicate = duplicate_membership
      vehicle_load = create(:load, vehicle: vehicle)
      ticket = create(:ticket_type, operator: operator)
      connection.remove_index :slots, name: "index_slots_on_load_id_and_membership_id"
      [oldest, duplicate].each do |member|
        Slot.new(load: vehicle_load, membership: member, body_mass_kg: 80, ticket_type: ticket, activity_type: ActivityType.first).save!(validate: false)
      end

      with_legacy_schema { run_quietly(migration, :merge_duplicate_memberships) }

      expect(Slot.where(load: vehicle_load).pluck(:membership_id)).to eq([oldest.id])
      expect(vehicle_load.reload.slots_count).to eq(1)
    end

    it "prefers the membership that was not archived" do
      oldest.discard
      current = duplicate_membership

      with_legacy_schema { run_quietly(migration, :merge_duplicate_memberships) }

      expect(Membership.where(user: user, operator: operator).pluck(:id)).to eq([current.id])
    end

    it "leaves memberships without duplicates alone" do
      other = create(:membership, operator: operator)
      before_rows = Membership.where(id: [other.id, oldest.id]).pluck(:id, :credits_cents)

      with_legacy_schema { run_quietly(migration, :merge_duplicate_memberships) }

      expect(Membership.where(id: [other.id, oldest.id]).pluck(:id, :credits_cents)).to eq(before_rows)
    end
  end

  describe AddDropzoneAndLoadDateToLoads do
    let(:migration) { described_class.new }

    before { connection.remove_index :loads, name: "index_loads_on_operator_id_and_load_date_and_load_number" }

    it "renumbers duplicate numbers of a day, the oldest load keeps its number" do
      first, second, third = Array.new(3) { create(:load, vehicle: vehicle) }
      second.update_columns(load_number: first.load_number)

      with_legacy_schema { run_quietly(migration, :renumber_duplicate_load_numbers) }

      expect([first, second, third].map { |load| load.reload.load_number }).to eq([1, 4, 3])
    end

    it "does not touch the numbers of other days or operators" do
      yesterday = create(:load, vehicle: vehicle, created_at: 1.day.ago)
      other = create(:load, vehicle: create(:vehicle, operator: create(:operator)))
      today = create(:load, vehicle: vehicle)
      before_numbers = [yesterday, other, today].map { |load| load.reload.load_number }

      with_legacy_schema { run_quietly(migration, :renumber_duplicate_load_numbers) }

      expect([yesterday, other, today].map { |load| load.reload.load_number }).to eq(before_numbers)
    end
  end

  describe AddUniqueOrderNumbersAndIndexes do
    let(:migration) { described_class.new }
    let(:buyer) { create(:membership, operator: operator) }

    before { connection.remove_index :orders, name: "index_orders_on_operator_id_and_order_number" }

    it "renumbers duplicate order numbers, the oldest order keeps its number" do
      first, second = Array.new(2) { create(:order, operator: operator, seller: operator, buyer: buyer) }
      second.update_columns(order_number: first.order_number)

      with_legacy_schema { run_quietly(migration, :renumber_duplicate_order_numbers) }

      expect([first, second].map { |order| order.reload.order_number }).to eq([1, 2])
    end
  end

  describe AddDateToWeatherConditionsAndDecimalMiles do
    let(:migration) { described_class.new }

    before { connection.remove_index :weather_conditions, name: "index_weather_conditions_on_operator_id_and_date" }

    it "keeps the most recently updated condition of a day" do
      older = WeatherCondition.create!(operator: operator, date: Date.new(2026, 10, 8))
      newer = WeatherCondition.create!(operator: operator, date: Date.new(2026, 10, 9))
      newer.update_columns(date: Date.new(2026, 10, 8), updated_at: 1.hour.from_now)
      other_day = WeatherCondition.create!(operator: operator, date: Date.new(2026, 10, 10))

      with_legacy_schema { run_quietly(migration, :remove_duplicate_days) }

      expect(WeatherCondition.where(operator: operator).pluck(:id)).to contain_exactly(newer.id, other_day.id)
      expect(WeatherCondition.exists?(older.id)).to be(false)
    end
  end

  describe AddCentsColumnsForMoney do
    let(:migration) { described_class.new }
    let(:member) { create(:membership, operator: operator) }

    it "backfills the cents from the old values, rounded" do
      ticket = create(:ticket_type, operator: operator, cost: 1)
      extra = Extra.create!(operator: operator, name: "Video", cost: 1)
      order = Order.create!(operator: operator, seller: operator, buyer: member)
      cents = {}

      with_legacy_schema do
        legacy_update(:dropzone_users, member.id, credits: 12.5, credits_cents: nil)
        legacy_update(:dropzones, operator.id, credits: 1000, credits_cents: nil)
        legacy_update(:ticket_types, ticket.id, cost: 19.99, cost_cents: nil)
        legacy_update(:extras, extra.id, cost: 0.1, cost_cents: nil)
        legacy_update(:orders, order.id, amount: 12.345, amount_cents: nil)

        run_quietly(migration, :backfill_cents)

        cents = {
          member: legacy_value(:dropzone_users, :credits_cents, member.id),
          operator: legacy_value(:dropzones, :credits_cents, operator.id),
          ticket: legacy_value(:ticket_types, :cost_cents, ticket.id),
          extra: legacy_value(:extras, :cost_cents, extra.id),
          order: legacy_value(:orders, :amount_cents, order.id),
        }
      end

      expect(cents).to eq(member: 1250, operator: 100_000, ticket: 1999, extra: 10, order: 1235)
    end

    it "leaves a missing value missing" do
      value = :unset
      member

      with_legacy_schema do
        legacy_update(:dropzone_users, member.id, credits: nil, credits_cents: nil)
        run_quietly(migration, :backfill_cents)
        value = legacy_value(:dropzone_users, :credits_cents, member.id)
      end

      expect(value).to be_nil
    end

    it "keeps the sums of the dev seed: the cents are the old values times 100" do
      members = create_list(:membership, 3, operator: operator)
      sums = []

      with_legacy_schema do
        members.zip([40, 12.5, 400]).each { |record, units| legacy_update(:dropzone_users, record.id, credits: units, credits_cents: nil) }

        run_quietly(migration, :backfill_cents)

        ids = members.map(&:id).join(", ")
        sums = [
          connection.select_value("SELECT SUM(credits_cents) FROM dropzone_users WHERE id IN (#{ids})"),
          connection.select_value("SELECT SUM(credits) FROM dropzone_users WHERE id IN (#{ids})") * 100,
        ]
      end

      expect(sums.first).to eq(sums.last.round)
    end
  end
end
