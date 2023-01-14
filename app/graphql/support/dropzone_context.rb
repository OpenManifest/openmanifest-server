module Support::DropzoneContext
  extend ActiveSupport::Concern

  class_methods do
    # Sets up a Dropzone argument for a mutation
    # or resolver, which will automatically resolve
    # the dropzone, and set the dropzone as the current
    # dropzone in the access context
    #
    # @return [GraphQL::Schema::Argument]
    def dropzone(symbol, **opts)
      argument symbol, GraphQL::Types::ID, **opts.merge(
        prepare: -> (value, ctx) {
                   ctx[:access_context].at_dropzone(value).dropzone
                 }
      )
    end
  end
end
