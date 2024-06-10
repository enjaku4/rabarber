# frozen_string_literal: true

module Rabarber
  module Core
    class Rule
      attr_reader :action, :roles, :context, :dynamic_rule, :negated_dynamic_rule

      def initialize(action, roles, context, dynamic_rule, negated_dynamic_rule)
        @action = action
        @roles = Array(roles)
        @context = context
        @dynamic_rule = dynamic_rule
        @negated_dynamic_rule = negated_dynamic_rule
      end

      def verify_access(roleable, controller_instance)
        roles_permitted?(roleable, controller_instance) && dynamic_rule_followed?(controller_instance)
      end

      def roles_permitted?(roleable, controller_instance)
        processed_context = get_context(controller_instance)

        return false if Rabarber::Configuration.instance.must_have_roles && roleable.roles(context: processed_context).empty?

        roles.empty? || roles.intersection(roleable.roles(context: processed_context)).any?
      end

      def dynamic_rule_followed?(controller_instance)
        !!(execute_dynamic_rule(controller_instance, false) && execute_dynamic_rule(controller_instance, true))
      end

      private

      def execute_dynamic_rule(controller_instance, is_negated)
        rule = is_negated ? negated_dynamic_rule : dynamic_rule

        return true if rule.nil?

        result = !!if rule.is_a?(Proc)
                     controller_instance.instance_exec(&rule)
                   else
                     controller_instance.send(rule)
                   end

        is_negated ? !result : result
      end

      def get_context(controller_instance)
        case context
        when Proc then Rabarber::Input::Context.new(controller_instance.instance_exec(&context)).process
        when Symbol then Rabarber::Input::Context.new(controller_instance.send(context)).process
        else context
        end
      end
    end
  end
end
