# frozen_string_literal: true

module ApplicationInteraction::Access
  extend ActiveSupport::Concern

  included do
    object :access_context, class: ApplicationInteraction::AccessContext, default: nil

    # Authorizes the current user for the given permissions
    # if any permissions were defined, and raises
    # ApplicationInteraction::PermissionDenied with an error
    # message if the user doesn't have the required permissions
    def authorize!
      permissions.each do |slug, message|
        raise PermissionDenied, message unless access_context.can?(slug)
      end
    end

    def permissions
      []
    end
  end

  class_methods do
    # Define what permissions should be required to perform this action
    # Permissions can be defined as a list of symbols or strings,
    # or a hash of permission slugs to error messages.
    # For example:
    # allow :updateDropzone
    # allow updateDropzone: 'You dont have permissions to update this dropzone'
    #
    # @param [Array<Symbol, String, Hash>] permissions
    # @return [void]
    def allow(*permissions)
      return unless permissions
      return if permissions.empty?

      permission_map = permissions.map do |permission|
        next permission if permission.is_a?(Hash)
        { permission => "You dont have access to #{self.action_name}. Missing permission: #{permission}" }
      end.reduce(:merge)
      define_method("permissions", -> { permission_map })
    end
  end
end
