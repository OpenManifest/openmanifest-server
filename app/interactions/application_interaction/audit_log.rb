# frozen_string_literal: true

module ApplicationInteraction::AuditLog
  extend ActiveSupport::Concern

  included do
    after do
      if errors.any?
        error
      else
        success
      end
    end

    def success
    end
    def error
    end
  end

  class_methods do
    def success(&block)
      define_method(:success, -> { instance_eval(&block) }) if block_given?
    end

    def error(&block)
      define_method(:error, -> { instance_eval(&block) }) if block_given?
    end
  end
end
