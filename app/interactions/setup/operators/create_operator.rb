# frozen_string_literal: true

class Setup::Operators::CreateOperator < ApplicationInteraction
  string :name
  string :banner, default: nil
  object :owner, class: User
  string :industry
  string :time_zone
  record :federation, default: nil
  boolean :request_publication, default: false
  boolean :is_public, default: false
  decimal :lat, default: 0.0
  decimal :lng, default: 0.0
  string :primary_color, default: "#FF0000"
  string :secondary_color, default: nil
  boolean :is_credit_system_enabled, default: false

  steps :build_operator,
        :create_roles,
        :build_owner,
        :apply_presets,
        :attach_banner,
        :save!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: ::ApplicationInteraction::AccessContext.new(@owner),
      level: :info,
      access_level: :admin,
      message: "Operator (#{@operator.name}) created by #{@owner.user.name}",
      resource: @operator,
      action: :created,
      created_by: @owner,
      operator: @operator,
    )
  end

  def build_owner
    @owner = Membership.new(
      operator: @operator,
      user: owner,
      user_role: UserRole.find_by(
        operator_id: @operator.id,
        name: "owner"
      )
    )
    errors.merge!(@owner.errors) unless @owner.save
    @owner
  end

  def build_operator
    @operator = Operator.new(
      name: name,
      industry: industry,
      time_zone: time_zone,
      federation: federation,
      request_publication: request_publication,
      is_public: is_public,
      lat: lat,
      lng: lng,
      primary_color: primary_color,
      secondary_color: secondary_color,
      is_credit_system_enabled: is_credit_system_enabled
    )
    save!
  end

  # The roles come first: the owner needs one
  def create_roles
    compose(::Setup::Operators::Access::CreateDefaults, operator: @operator)
  end

  # Everything else the industry template presets (ticket types, activity types, inspection form, ...)
  def apply_presets
    compose(::Presets::Apply, operator: @operator, created_by: @owner)
  end

  def attach_banner
    return if banner.blank?

    Support::ImageUpload.attach(@operator.banner, banner, name: "banner")
  rescue Support::ImageUpload::Invalid => e
    errors.add(:banner, e.message)
  end

  def save!
    errors.merge!(@operator.errors) unless @operator.save
    @operator
  end
end
