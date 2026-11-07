# frozen_string_literal: true

module Rabarber
  module Inputs
    class Boolean < Rabarber::Inputs::Base
      private

      def default_message = "Expected a boolean, got `#{@value.inspect}`"

      def validate_and_normalize = @value.equal?(true) || @value.equal?(false) ? @value : raise_error
    end
  end
end
