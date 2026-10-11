# frozen_string_literal: true

require "rails_helper"

# BUG-022: load numbers were today's count of kept loads plus one, so archiving a load repeated a number. BUG-050: the
# database now refuses duplicates.
RSpec.describe Load, "numbering" do
  let(:dropzone) { create(:dropzone, time_zone: "Australia/Brisbane") }
  let(:plane) { create(:plane, dropzone: dropzone) }

  def new_load(**attrs)
    create(:load, plane: plane, **attrs)
  end

  it "belongs to the dropzone of its plane" do
    expect(new_load.dropzone).to eq(dropzone)
  end

  it "numbers the loads of a day one after the other" do
    expect(Array.new(3) { new_load.load_number }).to eq([1, 2, 3])
  end

  it "does not repeat a number after a load is archived" do
    loads = Array.new(3) { new_load }
    loads[1].discard

    expect(new_load.load_number).to eq(4)
  end

  it "does not repeat the number of the last load after it is archived" do
    loads = Array.new(2) { new_load }
    loads.last.discard

    expect(new_load.load_number).to eq(3)
  end

  it "counts per dropzone" do
    other = create(:plane, dropzone: create(:dropzone))
    new_load

    expect(create(:load, plane: other).load_number).to eq(1)
  end

  it "counts per day in the dropzone's time zone" do
    yesterday = new_load(created_at: 1.day.ago)
    today = new_load

    expect([yesterday.load_number, today.load_number]).to eq([1, 1])
    expect(yesterday.load_date).to eq(1.day.ago.in_time_zone("Australia/Brisbane").to_date)
  end

  it "takes the day from the dropzone's time zone, not UTC" do
    # 15:30 UTC is 01:30 the next day in Brisbane (UTC+10)
    late = new_load(created_at: Time.utc(2026, 10, 8, 15, 30))

    expect(late.load_date).to eq(Date.new(2026, 10, 9))
  end

  it "refuses a duplicate number on the same day in the database" do
    first = new_load
    second = new_load

    expect { second.update_columns(load_number: first.load_number) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "refuses a load without a dropzone in the database" do
    expect { new_load.update_columns(dropzone_id: nil) }.to raise_error(ActiveRecord::NotNullViolation)
  end

  describe "orders" do
    it "numbers the orders of a dropzone one after the other, per dropzone" do
      seller = dropzone
      buyer = create(:dropzone_user, dropzone: dropzone)
      other_buyer = create(:dropzone_user, dropzone: create(:dropzone))

      numbers = Array.new(2) { create(:order, dropzone: dropzone, seller: seller, buyer: buyer).order_number }
      other = create(:order, dropzone: other_buyer.dropzone, seller: other_buyer.dropzone, buyer: other_buyer).order_number

      expect(numbers).to eq([1, 2])
      expect(other).to eq(1)
    end

    it "refuses a duplicate number in the database" do
      buyer = create(:dropzone_user, dropzone: dropzone)
      first = create(:order, dropzone: dropzone, seller: dropzone, buyer: buyer)
      second = create(:order, dropzone: dropzone, seller: dropzone, buyer: buyer)

      expect { second.update_columns(order_number: first.order_number) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "concurrently", :concurrent do
    def in_threads(count, &block)
      Array.new(count) do
        Thread.new { ActiveRecord::Base.connection_pool.with_connection { block.call } }
      end.map(&:value)
    end

    it "gives loads created at the same time different numbers" do
      plane
      other_plane = create(:plane, dropzone: dropzone)

      loads = in_threads(4) { create(:load, plane: [plane, other_plane].sample) }

      expect(loads.map(&:load_number).sort).to eq([1, 2, 3, 4])
    end

    it "gives orders created at the same time different numbers" do
      buyer = create(:dropzone_user, dropzone: dropzone)

      orders = in_threads(4) { Order.create!(dropzone: Dropzone.find(dropzone.id), seller: Dropzone.find(dropzone.id), buyer: DropzoneUser.find(buyer.id)) }

      expect(orders.map(&:order_number).sort).to eq([1, 2, 3, 4])
    end
  end
end
