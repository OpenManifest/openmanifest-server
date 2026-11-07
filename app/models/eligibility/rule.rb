# frozen_string_literal: true

module Eligibility
  # One rule. A subclass says its `code`, its `scope` (`:slot`, or `:manifest` for what a person chooses), whether it
  # `applies?` to an operator (its module is on) and, in `check`, what it finds in a context: a Result, a list of them,
  # or nothing at all when there is nothing for it to look at.
  class Rule
    class_attribute :bypass_permission, instance_writer: false, default: nil
    class_attribute :scope, instance_writer: false, default: :slot

    def applies?(_operator) = true

    def check(_context) = raise(NotImplementedError)

    # May a manifester with the permission let this failure through?
    def bypassable?(_result) = true

    protected

    # @param status [String] left out: PASS, or EXPIRING when `expires_at` is near
    def pass(code, expires_at: nil, amount_cents: nil)
      expiring = expires_at && expires_at > Time.current && expires_at < Time.current + EXPIRING_WITHIN
      Result.new(code: code, ok: true, status: expiring ? "EXPIRING" : "PASS", expires_at: expires_at, amount_cents: amount_cents)
    end

    def fail_with(code, message, problem: nil, field: nil, expires_at: nil, amount_cents: nil)
      Result.new(code: code, ok: false, status: "FAIL", message: message, problem: problem || code, field: field, expires_at: expires_at, amount_cents: amount_cents)
    end

    def not_required(code) = Result.new(code: code, ok: true, status: "NOT_REQUIRED")

    # The module configuration, e.g. `module_config(operator, :limits)["age"]`
    def module_flag?(operator, name, flag)
      config = operator.module_config(name)
      config.respond_to?(:[]) && config[flag.to_s] == true
    end
  end
end
