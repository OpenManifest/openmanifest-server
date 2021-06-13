module Types
  module AnyResourceType
    include Types::BaseInterface

    definition_methods do
      # Determine what object type to use for `object`
      def resolve_type(object, context)

        {
          Load => Types::LoadType,
          Slot => Types::SlotType,
          Rig => Types::RigType,
          TicketType => Types::TicketTypeType,
          Pack => Types::PackType,
          Plane => Types::PlaneType,
          DropzoneUser => Types::DropzoneUserType,
          User => Types::UserType
        }[object.class]
      end
    end
  end
end
