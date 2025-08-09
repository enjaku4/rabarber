# frozen_string_literal: true

module Rabarber
  module Inputs
    class Role < Base
      private

      def type = self.class::Coercible::Symbol.constrained(min_size: 1, format: /\A[a-z0-9_]+\z/)
    end
  end
end
