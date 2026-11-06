# frozen_string_literal: true

module Rabarber
  module Inputs
    class Boolean < Rabarber::Inputs::Base
      private

      def default_message = "Expected true or false, got `#{@value.inspect}`"

      def validate_and_normalize = @value == true || @value == false ? @value : raise_error
    end
  end
end
