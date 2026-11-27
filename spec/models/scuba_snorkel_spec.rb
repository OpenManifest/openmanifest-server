# frozen_string_literal: true

require "rails_helper"

# P7.24: the scuba and snorkel templates. A dive centre runs a two-site boat trip with certified divers, nitrox and a try
# dive guest; a snorkel operator runs the same boat without certifications, children coming with an adult.
RSpec.describe "Scuba and snorkel templates" do
  let(:owner) { create(:user) }
  let(:padi) { CertificationBody.find_by!(slug: "padi") }
  let(:ssi) { CertificationBody.find_by!(slug: "ssi") }

  def create_operator(industry, bodies: [])
    Setup::Operators::CreateOperator.run!(owner: owner, industry: industry, name: "Test #{industry}", time_zone: "Australia/Brisbane",
                                          certification_body_ids: bodies.map(&:id))
  end

  def member(operator, role: "customer", body: nil, rank: nil, qualifications: [], date_of_birth: Date.new(1990, 1, 1))
    user = create(:user, date_of_birth: date_of_birth)
    membership = create(:membership, operator: operator, user: user, user_role: operator.user_roles.find_by!(name: role), certification_level: nil)
    if body
      held = UserCertification.create!(user: user, certification_body: body, certification_level: body.certification_levels.find_by!(rank: rank))
      qualifications.each { |slug| held.user_qualifications.create!(qualification: body.qualifications.find_by!(slug: slug)) }
    end
    membership.refresh_certification_level
    membership.reload
  end

  def boat_trip(operator, sites:, crew:)
    boat = operator.vehicles.create!(name: "Boat #{operator.vehicles.count + 1}", registration: "B1", capacity: 10, kind: "boat")
    trip = Load.new(operator: operator, max_slots: 10, state: "open", is_open: true, name: "Trip")
    trip.vehicle = boat
    trip.destination_ids = sites.map(&:id)
    trip.crew_entries = crew.map { |key, membership| { crew_role: operator.crew_roles.find_by!(key: key), membership: membership } }
    trip.save!
    trip
  end

  def manifest(operator, trip, membership, ticket:, activity: nil, extras: [], guests: nil)
    manifester = operator.memberships.owner.first
    Manifest::CreateSlot.run(
      access_context: ApplicationInteraction::AccessContext.new(manifester),
      load: trip, membership: membership, ticket_type: operator.ticket_types.find_by!(name: ticket),
      activity_type: activity && ActivityType.find_by!(slug: activity), body_mass_kg: 75,
      extra_ids: extras.map { |name| operator.extras.find_by!(name: name).id }, guests: guests
    )
  end

  describe "the templates" do
    it "can be chosen, snorkel extending scuba on the water base" do
      expect(Industry.slugs).to include("scuba", "snorkel")
      expect(Industry.fetch("scuba")).to have_attributes(extends: "_water", family: "_water", icon: "diving-scuba-tank")
      expect(Industry.fetch("snorkel")).to have_attributes(extends: "scuba", family: "_water")
    end

    it "switches certifications and dive types off for snorkel, and keeps the rest of scuba's modules" do
      expect(Industry.fetch("scuba").modules.keys).to include("certifications", "activities", "equipment", "escorts", "limits", "crew")
      expect(Industry.fetch("snorkel").modules.keys).to include("equipment", "escorts", "limits", "crew", "destinations")
      expect(Industry.fetch("snorkel").modules.keys).not_to include("certifications", "activities", "conditions")
    end

    it "seeds the dive agencies with comparable ranks, tagged scuba; snorkel inherits none" do
      %w(padi ssi naui cmas raid sdi bsac).each do |slug|
        body = CertificationBody.find_by!(slug: slug)
        expect(body.industry).to eq("scuba")
        expect(body.certification_levels.find_by!(equivalence_key: "open_water").rank).to eq(20)
        expect(body.certification_levels.find_by!(equivalence_key: "advanced").rank).to eq(30)
        expect(body.qualifications.pluck(:slug)).to contain_exactly("nitrox", "instructor")
      end
      expect(padi.certification_levels.find_by!(rank: 30).name).to eq("Advanced Open Water Diver")
      expect(ssi.certification_levels.find_by!(rank: 30).name).to eq("Advanced Adventurer")
      expect(CertificationBody.for_industry("snorkel")).to be_empty
      expect(Industry.fetch("snorkel").catalogue).to eq("activity_types" => [], "certification_bodies" => {})
    end

    it "lets the deep and wreck dives start at the advanced rank" do
      expect(padi.certification_levels.find_by!(rank: 20).activity_types.pluck(:slug)).not_to include("deep_dive", "wreck_dive")
      expect(padi.certification_levels.find_by!(rank: 30).activity_types.pluck(:slug)).to include("deep_dive", "wreck_dive")
    end
  end

  describe "a dive centre" do
    let(:operator) { create_operator("scuba", bodies: [padi, ssi]) }
    let(:skipper) { member(operator, role: "skipper") }
    let(:supervisor) { member(operator, role: "divemaster", body: ssi, rank: 50) }
    let(:instructor) { member(operator, role: "instructor", body: padi, rank: 50, qualifications: %w(instructor)) }
    let(:advanced) { member(operator, body: padi, rank: 30) }
    let(:open_water) { member(operator, body: ssi, rank: 20) }
    let(:garden) { operator.destinations.find_by!(name: "Coral garden") }
    let(:wreck) { operator.destinations.find_by!(name: "The wreck") }

    it "gets the presets: roles, crew, sites with a depth and a rank, tickets, extras, gear and dive types" do
      expect(operator.user_roles.pluck(:name)).to include("customer", "divemaster", "instructor", "skipper", "front_desk")
      expect(operator.crew_roles.ordered.map { |role| [role.key, role.required, role.occupies_slot] }).
        to eq([["skipper", true, false], ["dive_supervisor", true, true], ["divemaster", false, true]])
      expect(wreck).to have_attributes(kind: "site", min_certification_rank: 30, location: { "max_depth_m" => 30 })
      expect(operator.ticket_types.find_by!(name: "Double-tank boat dive").min_certification_rank).to eq(20)
      expect(operator.ticket_types.find_by!(name: "Try dive")).to have_attributes(requires_escort: true, escort_capacity: 2,
                                                                                  participant_limits: { "min_age" => 10 },
                                                                                  escort_qualification: padi.qualifications.find_by!(slug: "instructor"))
      expect(operator.extras.find_by!(name: "Nitrox").required_qualification).to eq(padi.qualifications.find_by!(slug: "nitrox"))
      expect(operator.equipment_kinds.pluck(:key)).to eq(%w(bcd regulator wetsuit cylinder))
      expect(operator.activity_types.pluck(:slug)).to contain_exactly("fun_dive", "night_dive", "deep_dive", "wreck_dive", "drift_dive", "training_dive")
      expect(operator.terminology.dig("crew", "dive_supervisor", "one")).to eq("Dive supervisor")
    end

    it "takes an advanced diver to the wreck and keeps an open water diver off it" do
      trip = boat_trip(operator, sites: [garden, wreck], crew: { skipper: skipper, dive_supervisor: supervisor })

      expect(manifest(operator, trip, advanced, ticket: "Double-tank boat dive", activity: "wreck_dive")).to be_valid
      outcome = manifest(operator, trip, open_water, ticket: "Double-tank boat dive", activity: "fun_dive")
      expect(outcome).not_to be_valid
      expect(outcome.errors.full_messages.join).to match(/missing a certification for The wreck/)
    end

    it "takes an open water diver to the garden, but not on a deep dive" do
      trip = boat_trip(operator, sites: [garden], crew: { skipper: skipper, dive_supervisor: supervisor })

      expect(manifest(operator, trip, open_water, ticket: "Double-tank boat dive", activity: "fun_dive")).to be_valid
      deep = manifest(operator, trip, member(operator, body: padi, rank: 20), ticket: "Double-tank boat dive", activity: "deep_dive")
      expect(deep.errors.full_messages.join).to match(/certification does not permit Deep dive/)
    end

    it "sells nitrox only with a nitrox card, of any accepted agency" do
      trip = boat_trip(operator, sites: [garden], crew: { skipper: skipper, dive_supervisor: supervisor })

      outcome = manifest(operator, trip, advanced, ticket: "Double-tank boat dive", activity: "fun_dive", extras: ["Nitrox"])
      expect(outcome.errors.full_messages.join).to match(/missing a certification: qualification/)
      ssi_nitrox = member(operator, body: ssi, rank: 30, qualifications: %w(nitrox))
      expect(manifest(operator, trip, ssi_nitrox, ticket: "Double-tank boat dive", activity: "fun_dive", extras: ["Nitrox"])).to be_valid
    end

    it "lets an instructor take try dive guests from 10 years old" do
      trip = boat_trip(operator, sites: [garden], crew: { skipper: skipper, dive_supervisor: supervisor })

      young = manifest(operator, trip, instructor, ticket: "Try dive", activity: "training_dive",
                                                   guests: [{ name: "Kid", body_mass_kg: 30, date_of_birth: 8.years.ago.to_date }])
      expect(young.errors.full_messages.join).to match(/Kid must be at least 10 years old/)
      outcome = manifest(operator, trip, instructor, ticket: "Try dive", activity: "training_dive",
                                                     guests: [{ name: "Tess", body_mass_kg: 50, date_of_birth: 15.years.ago.to_date }])
      expect(outcome).to be_valid
      expect(outcome.result.guest_slots.sole.guest.name).to eq("Tess")
    end

    it "does not let a diver without the instructor qualification take guests" do
      trip = boat_trip(operator, sites: [garden], crew: { skipper: skipper, dive_supervisor: supervisor })

      outcome = manifest(operator, trip, advanced, ticket: "Try dive", activity: "training_dive",
                                                   guests: [{ name: "Tess", body_mass_kg: 50, date_of_birth: 15.years.ago.to_date }])
      expect(outcome.errors.full_messages.join).to match(/cannot escort guests: missing qualification/)
    end

    it "needs a skipper and a dive supervisor, and visits at most three sites" do
      boat = operator.vehicles.create!(name: "Boat", registration: "B", capacity: 10, kind: "boat")
      trip = Load.new(operator: operator, max_slots: 10, state: "open", is_open: true, name: "Trip")
      trip.vehicle = boat
      trip.destination_ids = operator.destinations.pluck(:id) + [operator.destinations.create!(name: "Pinnacle", kind: "site").id]

      expect(trip).not_to be_valid
      expect(trip.errors.full_messages).to include("Every load needs a Skipper", "Every load needs a Dive supervisor", "Destinations can include at most 3 places")
    end
  end

  describe "a snorkel operator" do
    let(:operator) { create_operator("snorkel") }
    let(:skipper) { member(operator, role: "skipper") }
    let(:adult) { member(operator, date_of_birth: Date.new(1985, 1, 1)) }

    it "gets the snorkel presets, without the dive centre's instructors or certifications" do
      expect(operator.user_roles.pluck(:name)).to include("customer", "skipper", "guide")
      expect(operator.user_roles.pluck(:name)).not_to include("instructor", "divemaster")
      expect(operator.crew_roles.ordered.pluck(:key)).to eq(%w(skipper guide))
      expect(operator.equipment_kinds.pluck(:key)).to eq(%w(mask fins stinger_suit))
      expect(operator.ticket_types.pluck(:name)).to contain_exactly("Snorkel trip", "Adult with children")
      expect(operator.module?(:certifications)).to be false
      expect(operator.require_certification?).to be false
      expect(operator.terminology.dig("guest", "other")).to eq("Children")
    end

    it "takes a child with an adult, and completes the trip" do
      trip = boat_trip(operator, sites: [operator.destinations.first], crew: { skipper: skipper })

      outcome = manifest(operator, trip, adult, ticket: "Adult with children", guests: [{ name: "Kit", body_mass_kg: 25, date_of_birth: 7.years.ago.to_date }])
      expect(outcome).to be_valid
      expect(trip.reload.slots_count).to eq(2)

      trip.update!(dispatch_at: 30.minutes.from_now, state: "boarding")
      trip.update!(state: "departed")
      trip.update!(state: "completed")
      expect(trip.reload.state).to eq("completed")
    end

    it "keeps a child under 12 off the trip on their own" do
      trip = boat_trip(operator, sites: [operator.destinations.first], crew: { skipper: skipper })
      child = member(operator, date_of_birth: 9.years.ago.to_date)

      outcome = manifest(operator, trip, child, ticket: "Snorkel trip")
      expect(outcome.errors.full_messages.join).to match(/must be at least 12 years old/)
    end
  end

  describe "the demo operators" do
    it "fill an operator with the template's vehicles, staff, divers and guests" do
      operator = create_operator("scuba", bodies: [padi, ssi])
      Demo::Generators::TemplateOperator.run!(operator: operator, email_prefix: "spec-")

      expect(operator.vehicles.pluck(:name)).to eq(["Reef Runner"])
      expect(User.find_by!(email: "spec-avery.advanced@example.com").at(operator).certification_level.name).to eq("Advanced Open Water Diver")
      expect(User.find_by!(email: "spec-indi.instructor@example.com").qualified_for?(padi.qualifications.find_by!(slug: "instructor"))).to be true
      expect(Guest.where(operator: operator).pluck(:name)).to eq(["Tess Trydive"])
      expect { Demo::Generators::TemplateOperator.run!(operator: operator, email_prefix: "spec-") }.not_to change(Membership, :count)
    end

    it "are what the demo generator makes for a template with demo data" do
      operator = create_operator("snorkel")

      expect(Demo::DataGenerator.run(operator: operator)).to be_valid
      expect(operator.memberships.joins(:user_role).pluck("user_roles.name")).to include("skipper", "guide", "customer")
      expect(operator.vehicles.pluck(:name)).to eq(["Lagoon Star"])
    end
  end
end
