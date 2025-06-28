# frozen_string_literal: true

module Rabarber
  module Input
    class Action < Rabarber::Input::Base
      def valid?
        Rabarber::Input::Types::Symbol.new(value).valid? || value.nil?
      end

      private

      def processed_value
        value&.to_sym
      end

      def default_error_message
        "Expected a symbol or a string, got #{value.inspect}"
      end
    end
  end
end
