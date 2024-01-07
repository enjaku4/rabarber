# frozen_string_literal: true

module Rabarber
  class Rule
    attr_reader :action, :roles, :custom

    def initialize(action, roles, custom)
      @action = pre_process_action(action)
      @roles = RoleNames.pre_process(Array(roles))
      @custom = pre_process_custom_rule(custom)
    end

    def verify_access(user_roles, custom_rule_receiver, action_name = nil)
      action_accessible?(action_name) && roles_permitted?(user_roles) && custom_rule_followed?(custom_rule_receiver)
    end

    def action_accessible?(action_name)
      action_name.nil? || action_name == action
    end

    def roles_permitted?(user_roles)
      return false if ::Rabarber::Configuration.instance.must_have_roles && user_roles.empty?

      roles.empty? || (roles & user_roles).any?
    end

    def custom_rule_followed?(custom_rule_receiver)
      custom.nil? || execute_custom_rule(custom_rule_receiver)
    end

    private

    def execute_custom_rule(custom_rule_receiver)
      if custom.is_a?(Proc)
        custom_rule_receiver.instance_exec(&custom)
      else
        custom_rule_receiver.send(custom)
      end
    end

    def pre_process_action(action)
      return action.to_sym if (action.is_a?(String) || action.is_a?(Symbol)) && action.present?
      return action if action.nil?

      raise InvalidArgumentError, "Action name must be a Symbol or a String"
    end

    def pre_process_custom_rule(custom)
      return custom.to_sym if (custom.is_a?(String) || custom.is_a?(Symbol)) && action.present?
      return custom if custom.nil? || custom.is_a?(Proc)

      raise InvalidArgumentError, "Custom rule must be a Symbol, a String, or a Proc"
    end
  end
end
