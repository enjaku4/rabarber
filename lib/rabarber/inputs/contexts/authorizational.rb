# frozen_string_literal: true

module Rabarber
  module Inputs
    module Contexts
      class Authorizational < Rabarber::Inputs::Context
        private

        def default_message = "Expected a Class, an instance of ActiveRecord model, a symbol, a string, or a proc, got `#{@value.inspect}`"

        def validate_and_normalize
          return @value if @value.is_a?(Proc)
          return @value.to_sym if (@value.is_a?(String) || @value.is_a?(Symbol)) && @value.present?

          super
        end
      end
    end
  end
end
