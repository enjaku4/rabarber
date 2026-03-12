# frozen_string_literal: true

module Rabarber
  module Inputs
    class Model < Rabarber::Inputs::Base
      private

      def validate_and_normalize
        model = @value.try(:safe_constantize)
        raise_error unless model.is_a?(Class) && model < ActiveRecord::Base

        model
      end
    end
  end
end
