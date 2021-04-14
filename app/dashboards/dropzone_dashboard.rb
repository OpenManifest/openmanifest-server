require "administrate/base_dashboard"

class DropzoneDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    dropzone_users: Field::HasMany,
    users: Field::HasMany,
    planes: Field::HasMany,
    loads: Field::HasMany,
    load_masters: Field::HasMany,
    federation: Field::BelongsTo,
    id: Field::Number,
    name: Field::String,
    lat: Field::Number.with_options(decimals: 2),
    lng: Field::Number.with_options(decimals: 2),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    dropzone_users
    users
    planes
    loads
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    dropzone_users
    users
    planes
    loads
    load_masters
    federation
    id
    name
    lat
    lng
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    dropzone_users
    users
    planes
    loads
    load_masters
    federation
    name
    lat
    lng
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

  # Overwrite this method to customize how dropzones are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(dropzone)
  #   "Dropzone ##{dropzone.id}"
  # end
end
