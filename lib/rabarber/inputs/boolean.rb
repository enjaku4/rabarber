# frozen_string_literal: true

module Rabarber
  module Inputs
    class Boolean < Rabarber::Inputs::Base
      private

      def type = self.class::Strict::Bool
    end
  end
end
