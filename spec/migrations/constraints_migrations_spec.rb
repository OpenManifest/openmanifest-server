# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261009110000_add_unique_index_to_dropzone_users_on_user_and_dropzone")
require Rails.root.join("db/migrate/20261009110100_add_dropzone_and_load_date_to_loads")
require Rails.root.join("db/migrate/20261009110200_add_unique_order_numbers_and_indexes")

# The data steps of the P6.16 migrations, run against rows that the unique indexes would not let exist: the example's
# transaction drops the index (PostgreSQL DDL is transactional) and rolls everything back at the end.
RSpec.describe "P6.16 constraint migrations" do
  let(:connection) { ActiveRecord::Base.connection }
  let(:dropzone) { create(:dropzone) }
  let(:plane) { create(:plane, dropzone: dropzone) }

  def run_quietly(migration, step)
    ActiveRecord::Migration.suppress_messages { migration.public_send(step) }
  end

  describe AddUniqueIndexToDropzoneUsersOnUserAndDropzone do
    let(:migration) { described_class.new }
    let(:user) { create(:user) }
    let!(:oldest) { create(:dropzone_user, dropzone: dropzone, user: user, credits: 100, jump_count: 5) }

    before { connection.remove_index :dropzone_users, name: described_class::INDEX }

    def duplicate_membership(**attrs)
      DropzoneUser.new(dropzone: dropzone, user: user, user_role: oldest.user_role, license: oldest.license, **attrs).tap { |member| member.save!(validate: false) }
    end

    it "merges the duplicates into the oldest membership" do
      duplicate = duplicate_membership(credits: 40, jump_count: 2)

      run_quietly(migration, :merge_duplicate_memberships)

      expect(DropzoneUser.where(id: duplicate.id)).to be_empty
      expect(oldest.reload).to have_attributes(credits: 140, jump_count: 7)
      expect(DropzoneUser.where(user: user, dropzone: dropzone).count).to eq(1)
    end

    it "moves what pointed at a duplicate to the oldest membership" do
      duplicate = duplicate_membership
      plane_load = create(:load, plane: plane, gca: duplicate, pilot: duplicate)
      slot = Slot.new(load: plane_load, dropzone_user: duplicate, created_by: duplicate, exit_weight: 80,
                      ticket_type: create(:ticket_type, dropzone: dropzone), jump_type: JumpType.first).tap { |new_slot| new_slot.save!(validate: false) }
      order = create(:order, dropzone: dropzone, seller: dropzone, buyer: duplicate)
      duplicate.grant!(:actAsPilot)

      run_quietly(migration, :merge_duplicate_memberships)

      expect(plane_load.reload).to have_attributes(gca_id: oldest.id, pilot_id: oldest.id)
      expect(slot.reload).to have_attributes(dropzone_user_id: oldest.id, created_by_id: oldest.id)
      expect(order.reload.buyer).to eq(oldest)
      expect(oldest.reload.permissions.pluck(:name)).to include("actAsPilot")
    end

    it "keeps one slot where several memberships were on the same load, and fixes the counters" do
      duplicate = duplicate_membership
      plane_load = create(:load, plane: plane)
      ticket = create(:ticket_type, dropzone: dropzone)
      connection.remove_index :slots, name: "index_slots_on_load_id_and_dropzone_user_id"
      [oldest, duplicate].each do |member|
        Slot.new(load: plane_load, dropzone_user: member, exit_weight: 80, ticket_type: ticket, jump_type: JumpType.first).save!(validate: false)
      end

      run_quietly(migration, :merge_duplicate_memberships)

      expect(Slot.where(load: plane_load).pluck(:dropzone_user_id)).to eq([oldest.id])
      expect(plane_load.reload.slots_count).to eq(1)
    end

    it "prefers the membership that was not archived" do
      oldest.discard
      current = duplicate_membership

      run_quietly(migration, :merge_duplicate_memberships)

      expect(DropzoneUser.where(user: user, dropzone: dropzone).pluck(:id)).to eq([current.id])
    end

    it "leaves memberships without duplicates alone" do
      other = create(:dropzone_user, dropzone: dropzone)

      expect { run_quietly(migration, :merge_duplicate_memberships) }.not_to(change { DropzoneUser.where(id: [other.id, oldest.id]).pluck(:id, :credits) })
    end
  end

  describe AddDropzoneAndLoadDateToLoads do
    let(:migration) { described_class.new }

    before { connection.remove_index :loads, name: described_class::INDEX }

    it "renumbers duplicate numbers of a day, the oldest load keeps its number" do
      first, second, third = Array.new(3) { create(:load, plane: plane) }
      second.update_columns(load_number: first.load_number)

      run_quietly(migration, :renumber_duplicate_load_numbers)

      expect([first, second, third].map { |load| load.reload.load_number }).to eq([1, 4, 3])
    end

    it "does not touch the numbers of other days or dropzones" do
      yesterday = create(:load, plane: plane, created_at: 1.day.ago)
      other = create(:load, plane: create(:plane, dropzone: create(:dropzone)))
      today = create(:load, plane: plane)

      expect { run_quietly(migration, :renumber_duplicate_load_numbers) }.not_to(change { [yesterday, other, today].map { |load| load.reload.load_number } })
    end
  end

  describe AddUniqueOrderNumbersAndIndexes do
    let(:migration) { described_class.new }
    let(:buyer) { create(:dropzone_user, dropzone: dropzone) }

    before { connection.remove_index :orders, name: described_class::ORDER_INDEX }

    it "renumbers duplicate order numbers, the oldest order keeps its number" do
      first, second = Array.new(2) { create(:order, dropzone: dropzone, seller: dropzone, buyer: buyer) }
      second.update_columns(order_number: first.order_number)

      run_quietly(migration, :renumber_duplicate_order_numbers)

      expect([first, second].map { |order| order.reload.order_number }).to eq([1, 2])
    end
  end
end
