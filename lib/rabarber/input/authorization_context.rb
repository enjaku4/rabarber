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
        when Symbol, String then value.to_sym
        when Proc then value
        else Rabarber::Input::Context.new(value).process
        end
      end

      def default_error_message
        "Context must be a Class, an instance of ActiveRecord model, a Symbol, a String, or a Proc"
      end
    end
  end
end
