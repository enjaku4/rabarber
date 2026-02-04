# frozen_string_literal: true

module Rabarber
  module Inputs
    class NonEmptyString < Rabarber::Inputs::Base
      private

      def processor = -> { @value.is_a?(String) && !@value.empty? ? @value : raise_error }
    end
  end
end
