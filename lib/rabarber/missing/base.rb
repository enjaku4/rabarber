# frozen_string_literal: true

module Rabarber
  module Missing
    class Base
      attr_reader :controller

      def initialize(controller = nil)
        @controller = controller
      end

      def handle
        check_controller_rules
        check_action_rules

        return if missing_list.empty?

        missing_list.each do |item|
          context = item.action ? { controller: item.controller, action: item.action } : { controller: item.controller }
          Rabarber::Configuration.instance.public_send(configuration_name).call(item.missing, context)
        end
      end

      private

      def check_controller_rules
        raise NotImplementedError
      end

      def check_action_rules
        raise NotImplementedError
      end

      def configuration_name
        raise NotImplementedError
      end

      def missing_list
        @missing_list ||= []
      end

      def controller_rules
        if controller
          Rabarber::Core::Permissions.controller_rules.slice(controller)
        else
          Rabarber::Core::Permissions.controller_rules
        end
      end

      def action_rules
        if controller
          Rabarber::Core::Permissions.action_rules.slice(controller)
        else
          Rabarber::Core::Permissions.action_rules
        end
      end
    end

    Item = Struct.new(:missing, :controller, :action)
  end
end
