# frozen_string_literal: true

module Rabarber
  class Rule
    attr_reader :action, :roles, :dynamic_rule, :negated_dynamic_rule

    def initialize(action, roles, dynamic_rule, negated_dynamic_rule)
      @action = action
      @roles = Array(roles)
      @dynamic_rule = dynamic_rule
      @negated_dynamic_rule = negated_dynamic_rule
    end

    def verify_access(user_roles, dynamic_rule_receiver, action_name = nil)
      action_accessible?(action_name) && roles_permitted?(user_roles) && dynamic_rule_followed?(dynamic_rule_receiver)
    end

    def action_accessible?(action_name)
      action_name.nil? || action_name == action
    end

    def roles_permitted?(user_roles)
      return false if Rabarber::Configuration.instance.must_have_roles && user_roles.empty?

      roles.empty? || (roles & user_roles).any?
    end

    def dynamic_rule_followed?(dynamic_rule_receiver)
      !!(execute_dynamic_rule(dynamic_rule_receiver, false) && execute_dynamic_rule(dynamic_rule_receiver, true))
    end

    private

    def execute_dynamic_rule(dynamic_rule_receiver, is_negated)
      rule = is_negated ? negated_dynamic_rule : dynamic_rule

      return true if rule.nil?

      result = if rule.is_a?(Proc)
                 dynamic_rule_receiver.instance_exec(&rule)
               else
                 dynamic_rule_receiver.send(rule)
               end

      is_negated ? !result : result
    end
  end
end
