# frozen_string_literal: true

module Rabarber
  module Input
    module Types
      class ArModel < Rabarber::Input::Base
        def valid?
          value.is_a?(Class) && value < ActiveRecord::Base
        end

        private

        def processed_value
          value
        end

        def default_error_message
          "Value must be an ActiveRecord model"
        end
      end
    end
  end
end
