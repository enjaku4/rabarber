# frozen_string_literal: true

module Rabarber
  module Inputs
    class Role < Rabarber::Inputs::Base
      private

      def validate_and_normalize
        raise_error unless (@value.is_a?(String) || @value.is_a?(Symbol)) && @value.to_s.match?(/\A[a-z0-9_]+\z/)

        @value.to_sym
      end
    end
  end
end
