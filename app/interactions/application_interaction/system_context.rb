class ApplicationInteraction::SystemContext < ApplicationInteraction::AccessContext
  def initialize(dropzone = nil)
    @dropzone = dropzone
  end

  def subject
    OpenStruct.new(
      user: user
    )
  end

  def user
    OpenStruct.new(
      name: 'System'
    )
  end

  def can?(*args)
    true
  end

  attr_reader :dropzone
end
