# frozen_string_literal: true

require "rails_helper"

# Solid Cache and Solid Cable (and Solid Queue, see jobs_spec) run on the primary database, so Redis is not needed anywhere.
RSpec.describe "The Solid stack" do
  def deadline_wait(seconds = 5)
    deadline = Time.current + seconds
    sleep 0.02 until yield || Time.current > deadline
  end

  it "does not depend on Redis" do
    expect(Gem.loaded_specs).not_to include("redis")
    expect(Rails.root.join("Gemfile.lock").read).not_to match(/^\s+redis(-client)? \(/)
    expect(Rails.root.glob("{app,config,lib}/**/*.{rb,yml}").grep_v(%r{/spec/}).select { |file| File.read(file).match?(/redis/i) }).to be_empty
  end

  describe "Solid Cache" do
    let(:store) { ActiveSupport::Cache.lookup_store(:solid_cache_store) }

    it "is the production cache store" do
      production = Rails.root.join("config/environments/production.rb").read

      expect(production).to match(/config\.cache_store = :solid_cache_store/)
    end

    it "stores, reads, fetches and deletes entries in the database" do
      store.write("greeting", { "hello" => "world" })

      expect(store.read("greeting")).to eq("hello" => "world")
      expect(SolidCache::Entry.count).to eq(1)
      computed = 0
      expect(store.fetch("answer") { computed += 1 }).to eq(1)
      expect(store.fetch("answer") { computed += 1 }).to eq(1)
      expect(computed).to eq(1)

      store.delete("greeting")

      expect(store.read("greeting")).to be_nil
    end

    it "expires entries" do
      store.write("short", 1, expires_in: 1.second)

      travel 2.seconds do
        expect(store.read("short")).to be_nil
      end
    end
  end

  describe "Solid Cable" do
    around do |example|
      pool = ActiveRecord::Base.connection_pool
      pool.pin_connection!(true)
      example.run
    ensure
      pool.unpin_connection!
    end

    let(:server) do
      ActionCable::Server::Base.new(config: ActionCable::Server::Configuration.new.tap do |config|
        config.logger = Logger.new(nil)
        config.cable = { "adapter" => "solid_cable", "polling_interval" => "0.05.seconds", "message_retention" => "1.day" }.with_indifferent_access
      end)
    end

    it "is the cable adapter of every environment but test" do
      cable = YAML.safe_load(ERB.new(Rails.root.join("config/cable.yml").read).result, aliases: true)

      expect(cable.slice("development", "staging", "production").values.pluck("adapter")).to all(eq("solid_cable"))
      expect(cable["test"]["adapter"]).to eq("test")
    end

    it "delivers a broadcast to a subscriber through the database table" do
      received = Queue.new
      server.pubsub.subscribe("openmanifest:test", ->(message) { received << message })
      sleep 0.2

      server.pubsub.broadcast("openmanifest:test", "hello")
      deadline_wait { !received.empty? }

      expect(received.empty? ? nil : received.pop).to eq("hello")
      expect(SolidCable::Message.where("created_at > ?", 1.minute.ago).count).to be >= 1
    ensure
      server.pubsub.shutdown
    end

    it "does not deliver a broadcast to another channel" do
      received = Queue.new
      server.pubsub.subscribe("openmanifest:one", ->(message) { received << message })
      sleep 0.2

      server.pubsub.broadcast("openmanifest:two", "not for you")
      sleep 0.5

      expect(received).to be_empty
    ensure
      server.pubsub.shutdown
    end
  end
end
