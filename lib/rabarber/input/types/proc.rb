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
          "Expected a proc, got #{value.inspect}"
        end
      end
    end
  end
end
