# frozen_string_literal: true

module Rabarber
  module Inputs
    class DynamicRule < Rabarber::Inputs::Base
      private

      def processor
        -> {
          return @value if @value.is_a?(Proc)

          Rabarber::Inputs::NonEmptySymbol.new(@value, error: @error, message: @message).process
        }
      end
    end
  end
end
