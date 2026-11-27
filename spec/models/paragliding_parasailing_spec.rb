# frozen_string_literal: true

require "rails_helper"

# P7.27: the tandem-paragliding template (aviation base) and the parasailing template (water base). A shuttle van takes
# tandem pilots and their passengers to a launch site: each passenger is the guest of one pilot who holds the tandem
# rating of an accepted association, within age and body-mass limits. A parasailing boat flies solo, tandem and triple
# flights as flight groups (slots of one group number) within each flight's size and combined body mass, each flyer
# within a minimum body mass; the captain and the winch operator are both needed.
RSpec.describe "Tandem-paragliding and parasailing templates" do
  let(:owner) { create(:user) }
  let(:safa) { CertificationBody.find_by!(slug: "safa") }

  def create_operator(industry, bodies: [])
    Setup::Operators::CreateOperator.run!(owner: owner, industry: industry, name: "Test #{industry}", time_zone: "Australia/Brisbane",
                                          certification_body_ids: bodies.map(&:id))
  end

  def member(operator, role: "customer", rating: nil, expires_at: 1.year.from_now, **attributes)
    user = create(:user, date_of_birth: Date.new(1985, 1, 1), **attributes)
    membership = create(:membership, operator: operator, user: user, user_role: operator.user_roles.find_by!(name: role), certification_level: nil)
    if rating
      held = UserCertification.create!(user: user, certification_body: rating)
      held.user_qualifications.create!(qualification: rating.qualifications.find_by!(slug: "tandem_pilot"), expires_at: expires_at)
    end
    membership.reload
  end

  def manifest(operator, load, membership, ticket:, body_mass_kg: 75, guests: nil, group_number: nil)
    Manifest::CreateSlot.run(
      access_context: ApplicationInteraction::AccessContext.new(operator.memberships.owner.first),
      load: load, membership: membership, ticket_type: operator.ticket_types.find_by!(name: ticket), body_mass_kg: body_mass_kg,
      guests: guests, group_number: group_number
    )
  end

  def passenger(name, body_mass_kg: 70, date_of_birth: 30.years.ago.to_date)
    { name: name, body_mass_kg: body_mass_kg, date_of_birth: date_of_birth }
  end

  describe "the templates" do
    it "can be chosen: paragliding on the aviation base with the flight log, parasailing on the water base with the passenger list" do
      expect(Industry.fetch("tandem_paragliding")).to have_attributes(extends: "_aviation", icon: "paragliding", daily_log_template: "flight_log",
                                                                      vehicle_kinds: %w(van), call_schedule_minutes: [30, 15])
      expect(Industry.fetch("tandem_paragliding").booking).to eq("manifest_link" => "checkin")
      expect(Industry.fetch("parasailing")).to have_attributes(extends: "_water", icon: "kite", daily_log_template: "guest_list",
                                                               vehicle_kinds: %w(boat), call_schedule_minutes: [30, 15])
    end

    it "turns on escorts, ratings, equipment and limits for paragliding; flight groups without places or escorts for parasailing" do
      paragliding = Industry.fetch("tandem_paragliding").modules
      parasailing = Industry.fetch("parasailing").modules
      expect(paragliding.keys).to include("destinations", "certifications", "equipment", "escorts", "crew", "limits", "daily_log")
      expect(paragliding["limits"]).to include("mass" => true, "age" => true)
      expect(paragliding.dig("destinations", "kinds")).to eq(["site"])
      expect(parasailing.keys).to include("equipment", "crew", "limits", "daily_log")
      expect(parasailing.keys).not_to include("destinations", "escorts", "certifications")
      expect(CertificationBody.for_industry("tandem_paragliding").pluck(:slug)).to contain_exactly("bhpa", "ushpa", "safa", "sahpa")
      expect(CertificationBody.for_industry("tandem_paragliding").flat_map { |body| body.qualifications.pluck(:slug) }.uniq).to eq(["tandem_pilot"])
      expect(CertificationBody.for_industry("parasailing")).to be_empty
    end
  end

  describe "a tandem-paragliding operator" do
    let(:operator) { create_operator("tandem_paragliding", bodies: [safa]) }
    let(:van) { operator.vehicles.create!(name: "Shuttle", registration: "PG1", capacity: 8, kind: "van") }
    let(:driver) { member(operator, role: "driver", name: "Dev Driver") }
    let(:site) { operator.destinations.find_by!(name: "North launch") }
    let(:pilots) { %w(Rhea Theo Wren).map { |name| member(operator, role: "tandem_pilot", rating: safa, name: "#{name} Pilot") } }

    def run(crew: [driver])
      run = Load.new(operator: operator, max_slots: van.capacity, state: "open", is_open: true, name: "Run")
      run.vehicle = van
      run.destination_ids = [site.id]
      run.crew_entries = crew.map { |membership| { crew_role: operator.crew_roles.find_by!(key: "driver"), membership: membership, vehicle: van } }
      run
    end

    it "gets the presets: a driver per van, launch sites, a tandem ticket for a rated pilot and one passenger, wing and harness" do
      expect(operator.crew_roles.ordered.map { |role| [role.key, role.scope, role.required, role.occupies_slot, role.vehicle_kinds] }).
        to eq([["driver", "vehicle", true, false, ["van"]]])
      expect(site.kind).to eq("site")
      tandem = operator.ticket_types.sole
      expect(tandem).to have_attributes(name: "Tandem flight", requires_escort: true, escort_capacity: 1, allow_manifesting_self: false,
                                        escort_qualification: safa.qualifications.find_by!(slug: "tandem_pilot"))
      expect(tandem.participant_limits).to eq("min_age" => 6, "min_body_mass_kg" => 20, "max_body_mass_kg" => 110)
      expect(operator.equipment_kinds.ordered.map { |kind| [kind.key, kind.inspection_form_template.present?] }).to eq([["wing", true], ["harness", true]])
      expect(operator.terminology.dig("escort", "one")).to eq("Tandem pilot")
      expect(operator.terminology.dig("load", "one")).to eq("Run")
      expect(operator.daily_logs.at(Date.current).template).to eq("flight_log")
    end

    it "asks a new operator to accept an association, whose rating the ticket then names" do
      expect { create_operator("tandem_paragliding") }.to raise_error(ActiveInteraction::InvalidInteractionError, /Certification bodies can't be blank/)
      bhpa = CertificationBody.find_by!(slug: "bhpa")
      expect(create_operator("tandem_paragliding", bodies: [bhpa]).ticket_types.sole.escort_qualification.certification_body).to eq(bhpa)
    end

    it "needs a driver for the van" do
      expect(run(crew: [])).not_to be_valid
      expect(run).to be_valid
    end

    it "takes three passengers with three pilots; a fourth has no pilot left to fly with" do
      shuttle = run.tap(&:save!)
      pilots.each_with_index do |pilot, index|
        expect(manifest(operator, shuttle, pilot, ticket: "Tandem flight", guests: [passenger("Passenger #{index + 1}")])).to be_valid
      end
      # The pilots take places on the van too
      expect(shuttle.reload.slots_count).to eq(6)

      # The driver holds no tandem rating
      unrated = manifest(operator, shuttle, driver, ticket: "Tandem flight", guests: [passenger("Passenger 4")])
      expect(unrated).not_to be_valid
      expect(unrated.errors.full_messages.join).to match(/Dev Driver cannot escort guests: missing qualification/)
      # A pilot flies one passenger at a time
      two = manifest(operator, shuttle, member(operator, role: "tandem_pilot", rating: safa), ticket: "Tandem flight",
                                                                                              guests: [passenger("Passenger 4"), passenger("Passenger 5")])
      expect(two.errors.full_messages.join).to match(/takes at most 1 guest for each escort/)
      expect(shuttle.reload.slots_count).to eq(6)
    end

    it "keeps an expired rating, and a passenger outside the age and body-mass limits, off" do
      shuttle = run.tap(&:save!)
      expired = manifest(operator, shuttle, member(operator, role: "tandem_pilot", rating: safa, expires_at: 1.day.ago), ticket: "Tandem flight",
                                                                                                                         guests: [passenger("Late")])
      expect(expired.errors.full_messages.join).to match(/missing qualification/)
      heavy = manifest(operator, shuttle, pilots.first, ticket: "Tandem flight", guests: [passenger("Heavy Hiker", body_mass_kg: 120)])
      expect(heavy.errors.full_messages.join).to match(/Heavy Hiker must weigh at most 110/)
      young = manifest(operator, shuttle, pilots.first, ticket: "Tandem flight", guests: [passenger("Tiny", body_mass_kg: 18, date_of_birth: 4.years.ago.to_date)])
      expect(young.errors.full_messages.join).to match(/Tiny must be at least 6 years old/)
      expect(manifest(operator, shuttle, pilots.first, ticket: "Tandem flight", guests: [passenger("Cam Cloud", body_mass_kg: 38, date_of_birth: 12.years.ago.to_date)])).to be_valid
    end
  end

  describe "a parasailing operator" do
    let(:operator) { create_operator("parasailing") }
    let(:boat) { operator.vehicles.create!(name: "Skyline", registration: "PS1", capacity: 12, kind: "boat") }
    let(:captain) { member(operator, role: "captain") }
    let(:winch) { member(operator, role: "winch_operator") }

    def trip(crew: { "captain" => captain, "winch_operator" => winch })
      trip = Load.new(operator: operator, max_slots: boat.capacity, state: "open", is_open: true, name: "Trip")
      trip.vehicle = boat
      trip.crew_entries = crew.map { |key, membership| { crew_role: operator.crew_roles.find_by!(key: key), membership: membership } }
      trip
    end

    it "gets the presets: captain and winch operator, solo, tandem and triple flights with their group limits, harnesses" do
      expect(operator.crew_roles.ordered.map { |role| [role.key, role.scope, role.required] }).to eq([["captain", "load", true], ["winch_operator", "load", true]])
      expect(operator.destinations).to be_empty
      expect(operator.ticket_types.order(:id).map { |ticket| [ticket.name, ticket.group_limits["max_group_size"]] }).
        to eq([["Solo flight", 1], ["Tandem flight", 2], ["Triple flight", 3]])
      expect(operator.ticket_types.find_by!(name: "Triple flight").group_limits).to eq("max_group_size" => 3, "max_group_body_mass_kg" => 225)
      expect(operator.equipment_kinds.pluck(:key)).to eq(["harness"])
      expect(operator.daily_logs.at(Date.current).template).to eq("guest_list")
      expect(operator.terminology.dig("crew", "winch_operator", "one")).to eq("Winch operator")
    end

    it "needs both the captain and the winch operator" do
      expect(trip(crew: { "captain" => captain })).not_to be_valid
      expect(trip(crew: { "winch_operator" => winch })).not_to be_valid
      expect(trip).to be_valid
    end

    it "blocks a triple flight over its combined body mass, and takes the three as a tandem and a solo" do
      flight = trip.tap(&:save!)
      flyers = [member(operator, name: "Fran Flyer"), member(operator, name: "Hal Heavy"), member(operator, name: "Kai Kite")]
      expect(manifest(operator, flight, flyers[0], ticket: "Triple flight", body_mass_kg: 85, group_number: 1)).to be_valid
      expect(manifest(operator, flight, flyers[1], ticket: "Triple flight", body_mass_kg: 95, group_number: 1)).to be_valid
      over = manifest(operator, flight, flyers[2], ticket: "Triple flight", body_mass_kg: 60, group_number: 1)
      expect(over).not_to be_valid
      expect(over.errors.full_messages.join).to match(/A flight group can weigh at most 225/)

      flight.slots.destroy_all
      expect(manifest(operator, flight, flyers[0], ticket: "Tandem flight", body_mass_kg: 85, group_number: 2)).to be_valid
      expect(manifest(operator, flight, flyers[1], ticket: "Tandem flight", body_mass_kg: 95, group_number: 2)).to be_valid
      expect(manifest(operator, flight, flyers[2], ticket: "Solo flight", body_mass_kg: 60, group_number: 3)).to be_valid
      expect(flight.reload.slots.group_by(&:group_number).transform_values(&:size)).to eq(2 => 2, 3 => 1)
    end

    it "keeps a group to its size and each flyer above the minimum body mass" do
      flight = trip.tap(&:save!)
      expect(manifest(operator, flight, member(operator), ticket: "Solo flight", body_mass_kg: 70, group_number: 1)).to be_valid
      second = manifest(operator, flight, member(operator), ticket: "Solo flight", body_mass_kg: 70, group_number: 1)
      expect(second.errors.full_messages.join).to match(/A flight group takes at most 1 people/)
      light = manifest(operator, flight, member(operator, name: "Lil Light"), ticket: "Solo flight", body_mass_kg: 40, group_number: 2)
      expect(light.errors.full_messages.join).to match(/Lil Light must weigh at least 45/)
      expect(manifest(operator, flight, member(operator), ticket: "Tandem flight", body_mass_kg: 40, group_number: 3)).to be_valid
    end
  end

  describe "the demo operators" do
    it "give the paragliding operator a van, three rated pilots, a driver without a rating and four passengers" do
      operator = create_operator("tandem_paragliding", bodies: [safa])
      Demo::Generators::TemplateOperator.run!(operator: operator, email_prefix: "spec-")
      expect(operator.vehicles.pluck(:name, :kind)).to eq([["Shuttle One", "van"]])
      rated = operator.memberships.select { |membership| membership.user.qualified_for?(operator.ticket_types.sole.escort_qualification, body_ids: [safa.id]) }
      expect(rated.map { |membership| membership.user.name }).to contain_exactly("Rhea Ridge", "Theo Thermal", "Wren Wingover")
      expect(User.find_by!(email: "spec-dev.driver@example.com").memberships.sole.user_role.name).to eq("driver")
      expect(Guest.where(operator: operator).count).to eq(4)
    end

    it "give the parasailing operator a boat, its crew and flyers with their body mass" do
      operator = create_operator("parasailing")
      expect(Demo::DataGenerator.run(operator: operator)).to be_valid
      expect(operator.vehicles.pluck(:name, :kind)).to eq([["Skyline", "boat"]])
      expect(operator.memberships.joins(:user).find_by!(users: { name: "Hal Heavy" }).user.body_mass_kg.to_i).to eq(95)
    end
  end
end
