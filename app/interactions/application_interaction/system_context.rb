class ApplicationInteraction::SystemContext < ApplicationInteraction::AccessContext
  def initialize(dropzone = nil)
    @dropzone = dropzone
  end

  def subject
    Struct.new(
      user: user
    )
  end

  def user
    Struct.new(
      name: 'System'
    )
  end

  def can?(*args)
    true
  end

  attr_reader :dropzone
end
