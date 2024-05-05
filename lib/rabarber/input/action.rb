# frozen_string_literal: true

module Rabarber
  module Input
    class Action < Rabarber::Input::Base
      def valid?
        Rabarber::Input::Types::Symbol.new(value).valid? || value.nil?
      end

      private

      def processed_value
        case value
        when String, Symbol then value.to_sym
        when nil then value
        end
      end

      def default_error_message
        "Action name must be a Symbol or a String"
      end
    end
  end
end
