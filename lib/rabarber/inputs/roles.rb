# frozen_string_literal: true

module Rabarber
  module Inputs
    class Roles < Rabarber::Inputs::Base
      private

      def type
        self.class::Array.of(self.class::Coercible::Symbol.constrained(min_size: 1, format: /\A[a-z0-9_]+\z/)).constructor { Kernel::Array(_1) }
      end
    end
  end
end
