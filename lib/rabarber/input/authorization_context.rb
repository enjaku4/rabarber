# frozen_string_literal: true

module Rabarber
  module Input
    class AuthorizationContext < Rabarber::Input::Base
      def valid?
        Rabarber::Input::Context.new(value).valid? || Rabarber::Input::DynamicRule.new(value).valid?
      end

      private

      def processed_value
        case value
        when String then value.to_sym
        when Symbol, Proc then value
        else Rabarber::Input::Context.new(value).process
        end
      end

      def default_error_message
        "Expected a Class, an instance of ActiveRecord model, a symbol, a string, or a proc, got #{value.inspect}"
      end
    end
  end
end
