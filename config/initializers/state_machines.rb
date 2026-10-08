# frozen_string_literal: true

# Load declares `enum :state` before its state machine (see Load). The enum already defines `open?`, `landed?` and the
# scopes the state machine would generate, with the same meaning, so the state machine should not warn about them.
StateMachines::Machine.ignore_method_conflicts = true
