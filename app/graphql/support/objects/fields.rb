module Support::Objects::Fields
  extend ActiveSupport::Concern

  class_methods do
    # Add basic timestamp fields to an object
    def timestamp_fields
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    end

    # Creates a dataloaded field for a polymorphic association
    def polymorphic_field(name, args = [])
      field name, Types::Interfaces::Polymorphic, *args
      define_method(name) do
        # Check if we have a `method` argument passed to the options
        column = args.last[:method] if args.last.is_a?(Hash) && args.last[:method]
        column ||= name
        reflection = object.class.reflections[column.to_s]
        class_name = object.send(reflection.foreign_type)
        return nil unless class_name
        return nil unless Types::Interfaces::Polymorphic.resolve_type(object.send(name), context)

        requested = dataloader.with(::Sources::Model, class_name.constantize).request(object.send(reflection.foreign_key))

        loaded = requested.load

        # Return nil and warn if this object isnt supported
        unless Types::Interfaces::Polymorphic.resolve_type(loaded, context)
          warn "#{loaded.class.name} cannot be resolved by Types::Interfaces::Polymorphic.resolve_type"
          return nil
        end
        loaded
      end
    end

    # Creates a dataloaded field for a belongs_to association
    def async_field(name, *args)
      field name, *args
      define_method(name) do
        # Check if we have a `method` argument passed to the options
        column = args.last[:method] if args.last.is_a?(Hash) && args.last[:method]
        column ||= name
        reflection = object.class.reflections[column.to_s]
        class_name = object.send(reflection.class_name)
        return nil unless class_name

        dataloader.with(::Sources::Model, class_name.constantize).load(object.send(reflection.foreign_key))
      end
    end
  end
end
