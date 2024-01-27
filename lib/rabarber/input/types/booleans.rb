# frozen_string_literal: true

module Rabarber
  module Input
    module Types
      class Booleans < Rabarber::Input::Base
        private

        def valid?
          [true, false].include?(value)
        end

        def processed_value
          value
        end
      end
    end
  end
end
