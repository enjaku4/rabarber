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
      end
    end
  end
end
