# frozen_string_literal: true

module Rabarber
  module Input
    class DynamicRule < Rabarber::Input::Base
      def valid?
        Rabarber::Input::Types::Symbol.new(value).valid? || Rabarber::Input::Types::Proc.new(value).valid? || value.nil?
      end

      private

      def processed_value
        case value
        when String, Symbol then value.to_sym
        when Proc, nil then value
        end
      end

      def default_error_message
        "Dynamic rule must be a Symbol, a String, or a Proc"
      end
    end
  end
end
