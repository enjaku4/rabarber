# frozen_string_literal: true

module Rabarber
  module Input
    module Types
      class Procs < Rabarber::Input::Base
        private

        def valid?
          value.is_a?(Proc)
        end

        def processed_value
          value
        end
      end
    end
  end
end
