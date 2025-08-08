# frozen_string_literal: true

module Rabarber
  module Inputs
    class NonEmptyString < Base
      private

      def type = self.class::Strict::String.constrained(min_size: 1)
    end
  end
end
