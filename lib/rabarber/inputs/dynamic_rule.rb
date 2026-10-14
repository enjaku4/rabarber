# frozen_string_literal: true

module Rabarber
  module Inputs
    class DynamicRule < Rabarber::Inputs::Base
      private

      def default_message = "Expected a symbol, a string, or a proc, got `#{@value.inspect}`"

      def validate_and_normalize
        return @value if @value.is_a?(Proc)

        Rabarber::Inputs::NonEmptySymbol.new(@value, error: @error || default_error, message: @message || default_message).process
      end
    end
  end
end
