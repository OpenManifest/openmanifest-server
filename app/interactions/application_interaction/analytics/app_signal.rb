# frozen_string_literal: true

module ApplicationInteraction::Analytics::AppSignal
  extend ::ActiveSupport::Concern

  prepended do
    set_callback :execute, :around, :benchmark, unless: :skip_appsignal?

    # Benchmark the interaction with AppSignal
    #
    # @param [ApplicationInteraction] _interaction
    # @param [Proc] block The block to execute (the interaction)
    def benchmark(&block)
      # Measure the whole transaction with AppSignal
      Appsignal.instrument("benchmark.active_interaction", self.class.name) do
        # Measure the time it took for the interaction to run
        interaction_time = Benchmark.measure(&block)

        # Track how this interaction performed over time
        Appsignal.add_distribution_value("benchmark.active_interaction.resolve_time", interaction_time.real.in_milliseconds,
                                         name: self.class.name)
      end
    end

    # Skip AppSignal instrumentation in test, or if
    # APPSIGNAL_DISABLE_INTERACTION_METRICS=true
    #
    # @return [Boolean]
    def skip_appsignal?
      return true if Rails.env.test?
      ENV.fetch("APPSIGNAL_DISABLE_INTERACTION_METRICS", nil)
    end
  end
end
