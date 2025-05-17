# frozen_string_literal: true

module Rabarber
  module Input
    class ArModel < Rabarber::Input::Base
      def valid?
        processed_value < ActiveRecord::Base
      rescue NameError
        false
      end

      private

      def processed_value
        value.constantize
      end

      def default_error_message
        "Value must be an ActiveRecord model"
      end
    end
  end
end
