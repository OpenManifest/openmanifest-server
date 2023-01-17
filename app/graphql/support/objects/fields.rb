module Support::Objects::Fields
  extend ActiveSupport::Concern

  class_methods do
    # Add basic timestamp fields to an object
    def timestamp_fields
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    end

    # Creates a dataloaded field for a polymorphic association
    def polymorphic_field(name, type_class = Types::Interfaces::Polymorphic, opts = { null: true })
      field name, type_class, **opts
      define_method(name) do
        # Check if we have a `method` argument passed to the options
        column = opts[:method]
        column ||= name
        reflection = object.class.reflections[column.to_s]
        class_name = object.send(reflection.foreign_type)
        return nil unless class_name
        return nil unless type_class.resolve_type(object.send(name), context)
        return unless object.send(reflection.foreign_key)
        requested = dataloader.with(::Sources::Model, class_name.constantize).request(object.send(reflection.foreign_key))

        loaded = requested.load

        # Return nil and warn if this object isnt supported
        unless type_class.resolve_type(loaded, context)
          warn "#{loaded.class.name} cannot be resolved by #{type_class.name}.resolve_type"
          return nil
        end
        loaded
      end
    end

    # Creates a dataloaded field for a belongs_to association
    def async_field(name, type, opts = { null: true })
      field name, type, **opts
      define_method(name) do
        # Check if we have a `method` argument passed to the options
        column = opts[:method]
        column ||= name
        reflection = object.class.reflections[column.to_s]
        return object.send(column) if reflection.nil? || reflection.macro != :belongs_to
        return nil unless reflection

        dataloader.with(::Sources::Model, reflection.class_name.constantize).load(object.send(reflection.foreign_key))
      end
    end
  end
end
