# frozen_string_literal: true

# Can this person be manifested on this load with this ticket? (GENERALISATION §11, P7.16)
#
# The server is the single source of truth: the core rules (capacity, membership, credits, double manifesting) always apply,
# each module contributes its own (certifications, equipment, limits, escorts) when the operator has it on. A rule gives a
# Result for the context it is asked about, or nothing when the context has nothing for it to look at. A failure may be
# bypassed by a manifester with the permission the rule names, when the operator allows it (`allow_manifest_bypass`).
#
#   Eligibility.check(Eligibility::Context.new(slot))              # every result, applicable rules only
#   Eligibility.failures(Eligibility::Context.new(slot))           # what stops the slot being saved
#   Eligibility.check(Eligibility::Context.for_member(membership)) # the member's side of it, for a checklist
module Eligibility
  STATUSES = %w(PASS EXPIRING FAIL NOT_REQUIRED).freeze
  # A date that falls within this long is shown as expiring
  EXPIRING_WITHIN = 14.days

  # @!attribute code [String] the rule: `capacity`, `membership`, `credits`, `double_manifest`, `activity`, `certification`,
  #   `equipment`, `equipment_inspection`, `equipment_service`, `age`, `body_mass`, `group`, `payload`, `escort`, …
  # @!attribute problem [String, nil] a more precise code when the rule fails, e.g. `date_of_birth_missing`
  # @!attribute field [Symbol, nil] the attribute of the slot an error belongs to (`base` when nil)
  Result = Struct.new(:code, :ok, :status, :message, :problem, :field, :expires_at, :amount_cents, :bypassed, keyword_init: true) do
    def ok? = ok

    def bypassed? = !!bypassed

    def failed? = !ok

    # Stops the save: failed, and not something the manifester may bypass
    def blocking? = failed? && !bypassed
  end

  # Where each rule sits. `:slot` rules are enforced whenever a slot is saved; `:manifest` rules only where a person
  # chooses what the slot needs (the manifest interactions, and the preview), so records made another way stay valid.
  RULE_NAMES = %w(Capacity Membership Credits DoubleManifest Activity Certification Escort Equipment Limits).freeze

  class << self
    def rules
      RULE_NAMES.map { |name| "Eligibility::Rules::#{name}".constantize.new }
    end

    # @param scopes [Array<Symbol>] `:slot` (what saving enforces) and `:manifest` (what choosing the slot's items checks)
    # @return [Array<Result>] one for each rule that has something to say, bypassed failures marked
    def check(context, scopes: %i(slot))
      operator = context.operator
      return [] if operator.nil?

      rules.select { |rule| scopes.include?(rule.scope) && rule.applies?(operator) }.flat_map do |rule|
        [rule.check(context)].flatten.compact.each { |result| mark_bypassed(rule, result, context) }
      end
    end

    # @return [Array<Result>] the results that stop a slot being saved
    def failures(context, scopes: %i(slot)) = check(context, scopes: scopes).select(&:blocking?)

    # The member's side of it, with every rule that can be told without a ticket: the checklist of a pick list
    # @return [Hash] `ready` and `rules`
    def summary(membership, load: nil)
      results = check(Context.for_member(membership, load: load), scopes: %i(slot manifest))
      { ready: results.none?(&:failed?), rules: results }
    end

    private

    def mark_bypassed(rule, result, context)
      return unless result.failed? && rule.bypass_permission && rule.bypassable?(result)

      result.bypassed = context.may_bypass?(rule.bypass_permission)
    end
  end
end
