# frozen_string_literal: true

module Rabarber
  module Core
    class Rule
      DEFAULT_DYNAMIC_RULE = -> { true }.freeze
      DEFAULT_NEGATED_DYNAMIC_RULE = -> { false }.freeze
      private_constant :DEFAULT_DYNAMIC_RULE, :DEFAULT_NEGATED_DYNAMIC_RULE

      def initialize(roles, context, dynamic_rule, negated_dynamic_rule)
        @roles = Array(roles)
        @context = context
        @dynamic_rule = dynamic_rule || DEFAULT_DYNAMIC_RULE
        @negated_dynamic_rule = negated_dynamic_rule || DEFAULT_NEGATED_DYNAMIC_RULE
      end

      def verify_access(roleable, controller_instance)
        roles_permitted?(roleable, controller_instance) && dynamic_rules_followed?(controller_instance)
      end

      def roles_permitted?(roleable, controller_instance)
        @roles.empty? || roleable.has_role?(*@roles, context: resolve_context(controller_instance))
      end

      def dynamic_rules_followed?(controller_instance)
        execute_rule(controller_instance, @dynamic_rule) && !execute_rule(controller_instance, @negated_dynamic_rule)
      end

      private

      def execute_rule(controller_instance, rule)
        !!(rule.is_a?(Proc) ? controller_instance.instance_exec(&rule) : controller_instance.send(rule))
      end

      def resolve_context(controller_instance)
        resolved_context = case @context
                           when Proc then controller_instance.instance_exec(&@context)
                           when Symbol then controller_instance.send(@context)
                           else @context
                           end
        Rabarber::Inputs::Context.new(resolved_context, message: "Expected an instance of ActiveRecord model, a Class, or nil, got #{resolved_context.inspect}").resolve
      end
    end
  end
end
