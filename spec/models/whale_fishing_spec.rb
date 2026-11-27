# frozen_string_literal: true

require "rails_helper"

# P7.25: the whale-watching and fishing-charter templates. Boat operators without certifications run a route with a
# passenger list; fishing charters check recreational fishing licences (a qualification with an expiry, no levels), which
# a licence-included ticket waives, and hire out rods and tackle. Both keep the guest list as their daily log.
RSpec.describe "Whale-watching and fishing-charter templates" do
  let(:owner) { create(:user) }
  let(:nsw) { CertificationBody.find_by!(slug: "nsw_fisheries") }
  let(:florida) { CertificationBody.find_by!(slug: "florida_fwc") }

  def create_operator(industry, bodies: [])
    Setup::Operators::CreateOperator.run!(owner: owner, industry: industry, name: "Test #{industry}", time_zone: "Australia/Brisbane",
                                          certification_body_ids: bodies.map(&:id))
  end

  def member(operator, role: "customer", licence: nil, expires_at: 1.year.from_now, **attributes)
    user = create(:user, date_of_birth: Date.new(1985, 1, 1), **attributes)
    membership = create(:membership, operator: operator, user: user, user_role: operator.user_roles.find_by!(name: role), certification_level: nil)
    if licence
      held = UserCertification.create!(user: user, certification_body: licence)
      held.user_qualifications.create!(qualification: licence.qualifications.find_by!(slug: "fishing_licence"), expires_at: expires_at)
    end
    membership.reload
  end

  def boat_trip(operator, places:, crew:)
    boat = operator.vehicles.create!(name: "Boat #{operator.vehicles.count + 1}", registration: "B1", capacity: 10, kind: "boat")
    trip = Load.new(operator: operator, max_slots: 10, state: "open", is_open: true, name: "Trip")
    trip.vehicle = boat
    trip.destination_ids = places.map(&:id)
    trip.crew_entries = crew.map { |key, membership| { crew_role: operator.crew_roles.find_by!(key: key), membership: membership } }
    trip.save!
    trip
  end

  def manifest(operator, trip, membership, ticket:, extras: [], guests: nil)
    manifester = operator.memberships.owner.first
    Manifest::CreateSlot.run(
      access_context: ApplicationInteraction::AccessContext.new(manifester),
      load: trip, membership: membership, ticket_type: operator.ticket_types.find_by!(name: ticket), body_mass_kg: 75,
      extra_ids: extras.map { |name| operator.extras.find_by!(name: name).id }, guests: guests
    )
  end

  def complete(trip)
    trip.update!(dispatch_at: 15.minutes.from_now, state: "boarding")
    trip.update!(state: "departed")
    trip.update!(state: "completed")
  end

  describe "the templates" do
    it "can be chosen, both on the water base, with the passenger list as their daily log" do
      expect(Industry.slugs).to include("whale_watching", "fishing_charter")
      expect(Industry.fetch("whale_watching")).to have_attributes(extends: "_water", family: "_water", icon: "dolphin", daily_log_template: "guest_list")
      expect(Industry.fetch("fishing_charter")).to have_attributes(extends: "_water", family: "_water", icon: "fish", daily_log_template: "guest_list")
      expect(Industry.fetch("whale_watching").call_schedule_minutes).to eq([30, 15])
    end

    it "keeps certifications and gear off for whale watching, and the licence and gear on for fishing" do
      expect(Industry.fetch("whale_watching").modules.keys).to include("destinations", "escorts", "crew", "daily_log")
      expect(Industry.fetch("whale_watching").modules.keys).not_to include("certifications", "activities", "equipment", "limits")
      expect(Industry.fetch("whale_watching").modules.dig("destinations", "kinds")).to eq(["route"])
      expect(Industry.fetch("fishing_charter").modules.keys).to include("certifications", "equipment", "escorts", "crew")
      expect(Industry.fetch("fishing_charter").modules.keys).not_to include("activities", "limits")
    end

    it "seeds one qualification-only body per jurisdiction, each with an expiring fishing licence" do
      %w(nsw_fisheries vic_fisheries florida_fwc alaska_adfg).each do |slug|
        body = CertificationBody.find_by!(slug: slug)
        expect(body.industry).to eq("fishing_charter")
        expect(body.certification_levels).to be_empty
        expect(body.qualifications.pluck(:slug, :name)).to eq([["fishing_licence", "Recreational fishing licence"]])
      end
      expect(CertificationBody.for_industry("whale_watching")).to be_empty
    end
  end

  describe "a whale-watching operator" do
    let(:operator) { create_operator("whale_watching") }
    let(:skipper) { member(operator, role: "skipper") }
    let(:naturalist) { member(operator, role: "naturalist") }
    let(:route) { operator.destinations.find_by!(name: "Bay run") }

    it "gets the presets: roles, crew, routes and adult, child and family tickets" do
      expect(operator.user_roles.pluck(:name)).to include("customer", "skipper", "deckhand", "naturalist", "front_desk")
      expect(operator.crew_roles.ordered.map { |role| [role.key, role.required, role.occupies_slot] }).
        to eq([["skipper", true, false], ["deckhand", false, false], ["naturalist", false, false]])
      expect(route.kind).to eq("route")
      expect(operator.ticket_types.pluck(:name)).to contain_exactly("Adult", "Adult with child", "Family")
      expect(operator.ticket_types.find_by!(name: "Family")).to have_attributes(requires_escort: true, escort_capacity: 3)
      expect(operator.equipment_kinds).to be_empty
      expect(operator.terminology.dig("load", "one")).to eq("Trip")
      expect(operator.terminology.dig("crew", "naturalist", "one")).to eq("Naturalist")
    end

    it "needs a skipper and goes on routes only" do
      trip = Load.new(operator: operator, max_slots: 10, state: "open", is_open: true, name: "Trip")
      trip.vehicle = operator.vehicles.create!(name: "Boat", registration: "B", capacity: 10, kind: "boat")
      expect(trip).not_to be_valid
      expect(trip.errors.full_messages).to include("Every load needs a Skipper")
      expect(operator.destinations.new(name: "Reef", kind: "site")).not_to be_valid
    end

    it "takes adults and a child, completes the trip and lists everyone with an emergency contact" do
      trip = boat_trip(operator, places: [route], crew: { skipper: skipper, naturalist: naturalist })
      adult = member(operator, name: "Wren Watcher", phone: "+61 400 111 222", emergency_contact: "Rob Watcher 0400 111 333")
      parent = member(operator, name: "Morgan Parent", phone: "0400 333 444")

      expect(manifest(operator, trip, adult, ticket: "Adult")).to be_valid
      expect(manifest(operator, trip, parent, ticket: "Adult with child", guests: [{ name: "Charlie Child", body_mass_kg: 22 }])).to be_valid
      complete(trip)
      expect(trip.reload).to have_attributes(state: "completed", slots_count: 3)

      log = operator.daily_logs.at(trip.dispatch_at.in_time_zone(operator.time_zone).to_date)
      expect(log.template).to eq("guest_list")
      entry = log.generate_json.fetch(:loads).sole
      expect(entry[:crew].map { |crew| crew.values_at(:role, :name) }).to eq([["Skipper", skipper.user.name], ["Naturalist", naturalist.user.name]])
      expect(entry[:destinations]).to eq(["Bay run"])
      expect(entry[:slots].map { |slot| slot.values_at(:name, :ticket_type, :escort, :activity_type) }).to eq(
        [["Wren Watcher", "Adult", nil, nil], ["Morgan Parent", "Adult with child", nil, nil], ["Charlie Child", "Adult with child", "Morgan Parent", nil]]
      )

      rows = CSV.parse(log.to_csv)
      expect(rows.first).to eq(["Trip", "Departure", "Name", "Phone", "Email", "Emergency contact", "Ticket", "With (adult)"])
      expect(rows.drop(1).map { |row| row.values_at(2, 3, 5, 7) }).to eq(
        [
          ["Wren Watcher", "+61 400 111 222", "Rob Watcher 0400 111 333", ""],
          ["Morgan Parent", "0400 333 444", "", ""],
          # A child without an emergency contact of their own has the adult's
          ["Charlie Child", "", "Morgan Parent 0400 333 444", "Morgan Parent"],
        ]
      )
      expect(rows.drop(1).map(&:first).uniq).to eq(["#{trip.load_number} Trip"])
    end

    it "quotes a cell a spreadsheet would run as a formula" do
      trip = boat_trip(operator, places: [route], crew: { skipper: skipper })
      sneaky = member(operator, name: "=HYPERLINK(\"x\")")
      expect(manifest(operator, trip, sneaky, ticket: "Adult")).to be_valid
      trip.update!(dispatch_at: 15.minutes.from_now, state: "boarding")

      log = operator.daily_logs.at(trip.dispatch_at.in_time_zone(operator.time_zone).to_date)
      expect(CSV.parse(log.to_csv).last[2]).to eq("'=HYPERLINK(\"x\")")
    end
  end

  describe "a fishing charter" do
    let(:operator) { create_operator("fishing_charter", bodies: [nsw]) }
    let(:skipper) { member(operator, role: "skipper") }
    let(:grounds) { operator.destinations.find_by!(name: "Offshore grounds") }
    let(:licence) { nsw.qualifications.find_by!(slug: "fishing_licence") }

    it "gets the presets: crew, grounds, tickets that ask for the licence or include it, hire extras, rods and tackle" do
      expect(operator.crew_roles.ordered.pluck(:key)).to eq(%w(skipper deckhand))
      expect(grounds.kind).to eq("site")
      expect(operator.ticket_types.find_by!(name: "Adult").required_qualification).to eq(licence)
      expect(operator.ticket_types.find_by!(name: "Adult, licence included").required_qualification).to be_nil
      expect(operator.ticket_types.find_by!(name: "Adult with children")).to have_attributes(requires_escort: true, escort_capacity: 2, required_qualification: licence)
      expect(operator.ticket_types.find_by!(name: "Adult").extras.pluck(:name)).to contain_exactly("Rod and reel hire", "Tackle pack")
      expect(operator.equipment_kinds.pluck(:key)).to eq(%w(rod tackle))
      expect(operator.require_certification?).to be false
      expect(operator.terminology.dig("certification_body", "one")).to eq("Licensing authority")
    end

    it "keeps an angler without a licence off the adult ticket, and takes them on the licence-included one" do
      trip = boat_trip(operator, places: [grounds], crew: { skipper: skipper })
      angler = member(operator, name: "Nico Nolicence")

      blocked = manifest(operator, trip, angler, ticket: "Adult", extras: ["Rod and reel hire"])
      expect(blocked).not_to be_valid
      expect(blocked.errors.full_messages.join).to match(/Nico Nolicence is missing a certification: qualification/)

      expect(manifest(operator, trip, angler, ticket: "Adult, licence included", extras: ["Rod and reel hire"])).to be_valid
      expect(trip.reload.slots.sole.extras.pluck(:name)).to eq(["Rod and reel hire"])
    end

    it "takes a current licence of an accepted authority only" do
      trip = boat_trip(operator, places: [grounds], crew: { skipper: skipper })

      expect(manifest(operator, trip, member(operator, licence: nsw), ticket: "Adult")).to be_valid
      expect(manifest(operator, trip, member(operator, licence: nsw, expires_at: 1.day.ago), ticket: "Adult")).not_to be_valid
      # The same licence of a jurisdiction the operator does not accept (BUG-133)
      expect(manifest(operator, trip, member(operator, licence: florida), ticket: "Adult")).not_to be_valid
    end

    it "takes a licensed adult with a child, who needs no licence" do
      trip = boat_trip(operator, places: [grounds], crew: { skipper: skipper })
      outcome = manifest(operator, trip, member(operator, licence: nsw), ticket: "Adult with children", guests: [{ name: "Rio", body_mass_kg: 35 }])
      expect(outcome).to be_valid
      expect(trip.reload.slots_count).to eq(2)
    end
  end

  describe "the demo operators" do
    it "give the fishing charter's licensed angler a licence that expires, and the passengers emergency contacts" do
      operator = create_operator("fishing_charter", bodies: [nsw])
      Demo::Generators::TemplateOperator.run!(operator: operator, email_prefix: "spec-")

      licensed = User.find_by!(email: "spec-lee.licensed@example.com")
      expect(licensed.user_qualifications.sole).to have_attributes(qualification: nsw.qualifications.sole, expires_at: be_present)
      expect(licensed.emergency_contact).to eq("Pat Licensed 0400 555 666")
      expect(licensed.qualified_for?(operator.ticket_types.find_by!(name: "Adult").required_qualification, body_ids: [nsw.id])).to be true
      expect(User.find_by!(email: "spec-nico.nolicence@example.com").user_qualifications).to be_empty
      expect { Demo::Generators::TemplateOperator.run!(operator: operator, email_prefix: "spec-") }.not_to change(UserQualification, :count)
    end

    it "are what the demo generator makes for whale watching" do
      operator = create_operator("whale_watching")

      expect(Demo::DataGenerator.run(operator: operator)).to be_valid
      expect(operator.memberships.joins(:user_role).pluck("user_roles.name")).to include("skipper", "deckhand", "naturalist", "customer")
      expect(operator.vehicles.pluck(:name)).to eq(["Ocean Spirit"])
      expect(Guest.where(operator: operator).pluck(:name)).to eq(["Charlie Child"])
    end
  end
end
