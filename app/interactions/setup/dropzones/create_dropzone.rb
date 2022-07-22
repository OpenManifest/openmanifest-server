# frozen_string_literal: true

class Setup::Dropzones::CreateDropzone < ApplicationInteraction
  string :name
  string :banner, default: nil
  object :owner, class: User
  record :federation
  boolean :request_publication, default: false
  boolean :is_public, default: false
  decimal :lat, default: 0.0
  decimal :lng, default: 0.0
  string :primary_color, default: "#FF0000"
  string :secondary_color, default: nil
  boolean :is_credit_system_enabled, default: false

  steps :build_dropzone,
        :build_owner,
        :build_rig_inspection_template,
        :save!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: ::ApplicationInteraction::AccessContext.new(@owner),
      level: :info,
      access_level: :admin,
      message: "Dropzone (#{@dropzone.name}) created by #{@owner.user.name}",
      resource: @dropzone,
      action: :created,
      created_by: @owner,
      dropzone: @dropzone,
    )
  end

  def build_owner
    @owner = DropzoneUser.new(
      dropzone: @dropzone,
      user: owner,
      user_role: UserRole.find_by(
        dropzone_id: @dropzone.id,
        name: "owner"
      )
    )
    errors.merge!(@owner.errors) unless @owner.save
    @owner
  end

  def build_dropzone
    @dropzone = Dropzone.new(
      name: name,
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

  def save!
    errors.merge!(@dropzone.errors) unless @dropzone.save
    @dropzone
  end

  def build_rig_inspection_template
    @dropzone.rig_inspection_template = FormTemplate.create(
      name: "Rig Inspection",
      definition: RigInspection.default_form.to_json,
      created_by: @owner,
      updated_by: @owner,
    )
    save!
    @dropzone.rig_inspection_template.update(dropzone: @dropzone)
    @dropzone
  end
end
