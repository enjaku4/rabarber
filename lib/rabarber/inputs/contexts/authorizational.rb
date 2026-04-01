# frozen_string_literal: true

module Rabarber
  module Inputs
    module Contexts
      class Authorizational < Rabarber::Inputs::Context
        def resolve
          result = process
          return result if result.is_a?(Symbol) || result.is_a?(Proc)

          super
        end

        private

        def validate_and_normalize
          return @value if @value.is_a?(Proc)
          return @value.to_sym if (@value.is_a?(String) || @value.is_a?(Symbol)) && @value.present?

          super
        end
      end
    end
  end
end
