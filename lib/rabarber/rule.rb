# frozen_string_literal: true

module Rabarber
  class Rule
    attr_reader :action, :roles, :dynamic_rule

    def initialize(action, roles, dynamic_rule)
      @action = pre_process_action(action)
      @roles = RoleNames.pre_process(Array(roles))
      @dynamic_rule = pre_process_dynamic_rule(dynamic_rule)
    end

    def verify_access(user_roles, dynamic_rule_receiver, action_name = nil)
      action_accessible?(action_name) && roles_permitted?(user_roles) && dynamic_rule_followed?(dynamic_rule_receiver)
    end

    def action_accessible?(action_name)
      action_name.nil? || action_name == action
    end

    def roles_permitted?(user_roles)
      return false if ::Rabarber::Configuration.instance.must_have_roles && user_roles.empty?

      roles.empty? || (roles & user_roles).any?
    end

    def dynamic_rule_followed?(dynamic_rule_receiver)
      dynamic_rule.nil? || execute_dynamic_rule(dynamic_rule_receiver)
    end

    private

    def execute_dynamic_rule(dynamic_rule_receiver)
      if dynamic_rule.is_a?(Proc)
        dynamic_rule_receiver.instance_exec(&dynamic_rule)
      else
        dynamic_rule_receiver.send(dynamic_rule)
      end
    end

    def pre_process_action(action)
      return action.to_sym if (action.is_a?(String) || action.is_a?(Symbol)) && action.present?
      return action if action.nil?

      raise InvalidArgumentError, "Action name must be a Symbol or a String"
    end

    def pre_process_dynamic_rule(dynamic_rule)
      return dynamic_rule.to_sym if (dynamic_rule.is_a?(String) || dynamic_rule.is_a?(Symbol)) && action.present?
      return dynamic_rule if dynamic_rule.nil? || dynamic_rule.is_a?(Proc)

      raise InvalidArgumentError, "Dynamic rule must be a Symbol, a String, or a Proc"
    end
  end
end
