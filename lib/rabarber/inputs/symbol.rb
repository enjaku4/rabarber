# frozen_string_literal: true

module Rabarber
  module Inputs
    class Symbol < Base
      private

      def type = self.class::Coercible::Symbol.constrained(min_size: 1)
    end
  end
end
