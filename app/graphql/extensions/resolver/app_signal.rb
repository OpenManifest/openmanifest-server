module Extensions::Resolver::AppSignal
  extend ActiveSupport::Concern

  class_methods do
    # Ensure this concern is included by
    # any subclasses of this class
    def inherited(child_class)
      # Must call super to not alter rails default behaviour
      super(child_class)
      child_class.include ::Extensions::Resolver::AppSignal
    end

    # Overrides the default GraphQL::Schema::Resolver#resolve_method
    # to enable AppSignal metrics by wrapping the default
    # resolve method in an AppSignal instrumented transaction
    def resolve_method
      :resolve_with_metrics
    end
  end

  included do
    # Wrapper around `resolve` to instrument the query
    # with AppSignal
    def resolve_with_metrics(**args)
      # No instrumentation in test environment
      return resolve(**args) if Rails.env.test?

      Appsignal.set_action(context.query.operation_name)
      Appsignal.instrument(
        'graphql.resolver',
        self.class.name,
        [
          'Variables: ',
          JSON.pretty_generate(Appsignal::Utils::HashSanitizer.sanitize(context.query.variables.to_h || {}, ['password'])),
          'Query: ',
          context.query.query_string,
        ].join("\n")
      ) do
        Appsignal.set_namespace('graphql')
        return resolve(**args)
      end
    end
  end
end