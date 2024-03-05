# frozen_string_literal: true

module Rabarber
  module Input
    module Types
      class Symbol < Rabarber::Input::Base
        def valid?
          (value.is_a?(::Symbol) || value.is_a?(String)) && value.present?
        end

        private

        def processed_value
          value.to_sym
        end

        def default_error_message
          "Value must be a Symbol or a String"
        end
      end
    end
  end
end
