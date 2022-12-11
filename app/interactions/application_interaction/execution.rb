# frozen_string_literal: true

module ApplicationInteraction::Execution
  extend ActiveSupport::Concern

  class_methods do
    def before_steps(symbol = nil, &block)
      @before_hooks = [] unless defined?(@before_hooks)
      @before_hooks << symbol unless symbol.nil?
      @before_hooks << block if block
      before_hooks = @before_hooks
      define_method(:before_hooks, -> { before_hooks || [] })
    end

    def after_steps(symbol = nil, &block)
      @after_hooks = [] unless defined?(@after_hooks)
      @after_hooks << symbol unless symbol.nil?
      @after_hooks << block if block
      after_hooks = @after_hooks
      define_method(:after_hooks, -> { after_hooks || [] })
    end

    # Execute these steps in order and fail if any error occurs:
    def steps(*method_symbols)
      return unless method_symbols
      return if method_symbols.empty?
      define_method(:steps, -> { method_symbols })
    end

    def action_name
      name.split("::").last.underscore.humanize
    end
  end

  included do
    def before_hooks
      []
    end

    def after_hooks
      []
    end

    # Execute all defined steps in order
    def execute
      authorize!
      return nil if errors.any?
      before_hooks.each do |method_or_block|
        if method_or_block.is_a?(Symbol)
          send(method_or_block)
        else
          instance_eval(&method_or_block)
        end
      end

      # Run steps
      *, result = steps.map do |step|
        value = send(step) if respond_to?(step)
        return nil if errors.any?
        value
      end

      # Run after hooks
      after_hooks.each do |method_or_block|
        if method_or_block.is_a?(Symbol)
          send(method_or_block)
        else
          instance_eval(&method_or_block)
        end
      end
      result
    end
  end
end
