# frozen_string_literal: true

module Rabarber
  module Input
    module Types
      class Proc < Rabarber::Input::Base
        def valid?
          value.is_a?(::Proc)
        end

        private

        def processed_value
          value
        end
      end
    end
  end
end
