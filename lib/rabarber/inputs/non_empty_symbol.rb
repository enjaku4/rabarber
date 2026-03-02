# frozen_string_literal: true

module Rabarber
  module Inputs
    class NonEmptySymbol < Rabarber::Inputs::Base
      private

      def processor
        -> {
          raise_error unless (@value.is_a?(String) || @value.is_a?(Symbol)) && @value.present?

          @value.to_sym
        }
      end
    end
  end
end
