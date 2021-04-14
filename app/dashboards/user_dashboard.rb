require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    rigs: Field::HasMany,
    packs: Field::HasMany,
    dropzone_users: Field::HasMany,
    dropzones: Field::HasMany,
    slots: Field::HasMany,
    loads: Field::HasMany,
    license: Field::BelongsTo,
    licensed_jump_types: Field::HasMany,
    jump_types: Field::HasMany,
    id: Field::Number,
    name: Field::String,
    email: Field::String,
    phone: Field::String,
    password: Field::String,
    password_digest: Field::String,
    exit_weight: Field::Number.with_options(decimals: 2),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    rigs
    packs
    dropzone_users
    dropzones
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    rigs
    packs
    dropzone_users
    dropzones
    slots
    loads
    license
    licensed_jump_types
    jump_types
    id
    name
    email
    phone
    password
    password_digest
    exit_weight
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    rigs
    packs
    dropzone_users
    dropzones
    slots
    loads
    license
    licensed_jump_types
    jump_types
    name
    email
    phone
    password
    password_digest
    exit_weight
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(user)
  #   "User ##{user.id}"
  # end
end
