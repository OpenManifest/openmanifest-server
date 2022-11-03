# frozen_string_literal: true

module StateMachines::DropzoneState
  extend ActiveSupport::Concern

  included do
    state_machine :state, initial: :private do

      event :request_publication do
        transition private: :in_review
      end

      event :publish do
        transition any => :public
      end

      event :unpublish do
        transition any => :public
      end

      event :archive do
        transition any => :archived
      end
    end
  end
end
