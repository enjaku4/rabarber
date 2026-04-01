# frozen_string_literal: true

module Rabarber
  module Inputs
    class NonEmptyString < Rabarber::Inputs::Base
      private

      def validate_and_normalize
        @value.is_a?(String) && @value.present? ? @value : raise_error
      end
    end
  end
end
