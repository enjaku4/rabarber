# frozen_string_literal: true

module Rabarber
  module Inputs
    module Contexts
      class Authorizational < Rabarber::Inputs::Context
        private

        def type = self.class::Coercible::Symbol.constrained(min_size: 1) | self.class::Instance(Proc) | super
      end
    end
  end
end
