# frozen_string_literal: true

module Rabarber
  module Input
    module Types
      class Boolean < Rabarber::Input::Base
        def valid?
          [true, false].include?(value)
        end

        private

        def processed_value
          value
        end

        def default_error_message
          "Value must be a Boolean"
        end
      end
    end
  end
end
