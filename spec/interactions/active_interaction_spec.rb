# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveInteraction do
  module InteractionSpec
    class SpecInteraction < ::ApplicationInteraction
      attr_accessor :sum
      steps :one,
            :two,
            :three

      before do warn "BLOCKRUN"; self.sum = 1 end
      def one
        self.sum += 1
      end

      def two
        self.sum += 1
      end

      def three
        self.sum += 1
      end
    end
  end
  describe ".run" do
    let!(:outcome) { InteractionSpec::SpecInteraction.run! }

    it { expect(outcome).to be_a Integer }
    it { expect(outcome).to eq 4 }
  end
end
