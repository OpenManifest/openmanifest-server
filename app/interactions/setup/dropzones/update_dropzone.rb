# frozen_string_literal: true

class Setup::Dropzones::UpdateDropzone < ApplicationInteraction
  record :dropzone
  string :name, default: nil
  string :banner, default: nil
  record :location, default: nil
  string :primary_color, default: "#FF0000"
  string :secondary_color, default: nil
  hash :settings, default: {} do
    boolean :require_license, default: nil
    boolean :require_credits, default: nil
    boolean :require_membership, default: nil
    boolean :allow_negative_credits, default: nil
    boolean :allow_manifest_bypass, default: nil
    boolean :require_reserve_in_date, default: nil
    boolean :require_equipment, default: nil
    boolean :allow_double_manifesting, default: nil
  end

  steps :assign_attributes,
        :attach_banner,
        :save!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :info,
      access_level: :admin,
      message: "Dropzone (#{dropzone.name}) updated by #{access_context.subject.name}",
      resource: dropzone,
      action: :created,
      created_by: access_context.subject,
      dropzone: dropzone,
    )
  end

  def assign_attributes
    dropzone.assign_attributes(
      {
        name: name,
        location: location,
        primary_color: primary_color,
        secondary_color: secondary_color,
      }.compact
    )
    return if settings.compact.empty?
    dropzone.settings = dropzone.settings.merge(settings.compact)
  end

  def attach_banner
    return if banner.blank?
    dropzone.banner.attach(data: banner)
    dropzone.banner.variant(resize_to_fill: [1280, 720], gravity: 'north')
  end

  def save!
    errors.merge!(dropzone.errors) unless dropzone.save
    dropzone
  end
end
