# frozen_string_literal: true

module Rabarber
  module Input
    class Role < Rabarber::Input::Base
      REGEX = /\A[a-z0-9_]+\z/

      def valid?
        Rabarber::Input::Types::Symbol.new(value).valid? && value.to_s.match?(REGEX)
      end

      private

      def processed_value
        value.to_sym
      end

      def default_error_message
        "Role name must be a Symbol or a String and may only contain lowercase letters, numbers, and underscores"
      end
    end
  end
end
