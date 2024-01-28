# frozen_string_literal: true

module Rabarber
  module Input
    module Types
      class Symbols < Rabarber::Input::Base
        private

        def valid?
          (value.is_a?(Symbol) || value.is_a?(String)) && value.present?
        end

        def processed_value
          value.to_sym
        end
      end
    end
  end
end
