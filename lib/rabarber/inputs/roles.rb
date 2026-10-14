# frozen_string_literal: true

module Rabarber
  module Inputs
    class Roles < Rabarber::Inputs::Base
      private

      def default_message = "Expected an array of symbols or strings containing only lowercase letters, numbers, and underscores, got `#{@value.inspect}`"

      def validate_and_normalize
        Array(@value).map do |role|
          Rabarber::Inputs::Role.new(role, error: @error || default_error, message: @message || default_message).process
        end
      end
    end
  end
end
