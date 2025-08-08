# frozen_string_literal: true

module Rabarber
  module Inputs
    class DynamicRule < Base
      private

      def type = self.class::Coercible::Symbol.constrained(min_size: 1) | self.class::Instance(Proc)
    end
  end
end
