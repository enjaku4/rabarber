# frozen_string_literal: true

module Rabarber
  class Rule
    attr_reader :action, :roles, :custom

    def initialize(action, roles, custom)
      @action = action
      @roles = Array(roles)
      @custom = custom
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
  end
end
