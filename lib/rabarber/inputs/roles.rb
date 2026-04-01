# frozen_string_literal: true

module Rabarber
  module Inputs
    class Roles < Rabarber::Inputs::Base
      private

      def validate_and_normalize
        Array(@value).map do |role|
          Rabarber::Inputs::Role.new(role, error: @error, message: @message).process
        end
      end
    end
  end
end
