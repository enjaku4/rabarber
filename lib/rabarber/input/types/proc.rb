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

        def default_error_message
          "Value must be a Proc"
        end
      end
    end
  end
end
