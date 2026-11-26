# frozen_string_literal: true

# Load and validate every industry template at boot (a broken template fails here, not on the first createOperator)
Rails.application.config.after_initialize { Industry.all }
