# frozen_string_literal: true

class Manifest::UpdateLoad < ApplicationInteraction
  allow :updateLoad

  # Arguments
  record :load
  date_time :dispatch_at, default: nil
  string :name, default: nil
  integer :max_slots, default: nil
  object :gca, class: DropzoneUser, default: nil
  object :load_master, class: DropzoneUser, default: nil
  object :pilot, class: DropzoneUser, default: nil
  object :plane, class: Plane, default: nil
  string :state, default: nil

  validates_inclusion_of :state, in: Load.states.keys, allow_nil: true

  steps :check_max_slots,
        :check_plane_change,
        :update_load,
        :save

  success do
    if dispatch_at
      time_left = (dispatch_at.to_i - DateTime.now.to_i) / 60
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        dropzone: access_context.dropzone,
        created_by: access_context.subject,
        message: "#{access_context.subject.user.name} dispatched load ##{load.load_number} (#{time_left} minute call)"
      )
    elsif given?(:dispatch_at)
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        dropzone: access_context.dropzone,
        created_by: access_context.subject,
        message: "#{access_context.subject.user.name} cancelled call for load ##{load.load_number}"
      )
    end

    if plane
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        dropzone: access_context.dropzone,
        created_by: access_context.subject,
        message: "#{access_context.subject.user.name} changed the plane for load ##{load.load_number} to #{plane.name} (#{plane.registration})"
      )
    end

    if gca
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        dropzone: access_context.dropzone,
        created_by: access_context.subject,
        message: "#{access_context.subject.user.name} changed the GCA for load ##{load.load_number} to #{gca.user.name}"
      )
    end

    if load_master
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        dropzone: access_context.dropzone,
        created_by: access_context.subject,
        message: "#{access_context.subject.user.name} changed the load master for load ##{load.load_number} to #{load_master.user.name}"
      )
    end
  end


  def check_max_slots
    return unless max_slots.present?
    errors.add(:base, "You have too many manifested jumpers") unless max_slots < load.slots.count
  end

  def check_plane_change
    return unless plane
    if plane.max_slots > load.slots.count
      load.assign_attributes(max_slots: plane.max_slots)
    else
      errors.add(:base, "This plane cannot fit all manifested jumpers")
    end
  end

  def update_load
    load.assign_attributes(dispatch_at: dispatch_at) if given?(:dispatch_at)
    load.assign_attributes(
      {
        max_slots: max_slots || load.max_slots || load.plane.max_slots,
        gca: gca,
        load_master: load_master,
        pilot: pilot,
        name: name,
        state: state
      }.compact
    )
  end

  def save
    errors.merge!(load.errors) unless load.save
    load
  end
end
