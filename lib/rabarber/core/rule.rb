# frozen_string_literal: true

module Rabarber
  module Core
    class Rule
      attr_reader :roles, :context, :dynamic_rule, :negated_dynamic_rule

      def initialize(roles, context, dynamic_rule, negated_dynamic_rule)
        @roles = Array(roles)
        @context = context
        @dynamic_rule = dynamic_rule || -> { true }
        @negated_dynamic_rule = negated_dynamic_rule || -> { false }
      end

      def verify_access(roleable, controller_instance)
        roles_permitted?(roleable, controller_instance) && dynamic_rules_followed?(controller_instance)
      end

      def roles_permitted?(roleable, controller_instance)
        return false if Rabarber::Configuration.instance.must_have_roles && roleable.all_roles.empty?

        roles.empty? || roleable.has_role?(*roles, context: resolve_context(controller_instance))
      end

      def dynamic_rules_followed?(controller_instance)
        execute_rule(controller_instance, dynamic_rule) && !execute_rule(controller_instance, negated_dynamic_rule)
      end

      private

      def execute_rule(controller_instance, rule)
        !!(rule.is_a?(Proc) ? controller_instance.instance_exec(&rule) : controller_instance.send(rule))
      end

      def resolve_context(controller_instance)
        case context
        when Proc then Rabarber::Input::Context.new(controller_instance.instance_exec(&context)).process
        when Symbol then Rabarber::Input::Context.new(controller_instance.send(context)).process
        else context
        end
      end
    end
  end
end
