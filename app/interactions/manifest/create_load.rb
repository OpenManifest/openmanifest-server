class Manifest::CreateLoad < ApplicationInteraction
  allow :createLoad

  string  :name,          default: ""
  integer :max_slots,     default: nil
  object  :pilot,         class: DropzoneUser, default: nil
  object  :gca,           class: DropzoneUser, default: nil
  object  :load_master,   class: DropzoneUser, default: nil
  object  :plane,         class: Plane
  string  :state,         default: "open"


  steps :build_load,
        :save

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: @load,
      action: :created,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} created load ##{load.load_number}"
    )
  end

  # Create events
  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      action: :created,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} failed to create a new load"
    )
  end

  def build_load
    @load = access_context.loads.new(
      name:         name,
      gca:          gca,
      pilot:        pilot,
      load_master:  load_master,
      plane:        plane,
      state:        state,
    )
  end

  def save
    errors.merge!(@load.errors) unless @load.save
    @load
  end
end
