# frozen_string_literal: true

module Rabarber
  class Rule
    attr_reader :action, :roles, :custom

    def initialize(action, roles, custom)
      @action = validate_action(action)
      @roles = validate_roles(roles)
      @custom = validate_custom_rule(custom)
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

    # TODO
    def validate_action(action)
      return action if action.nil? || action.is_a?(Symbol)

      raise InvalidArgumentError, "Action name must be a Symbol"
    end

    # TODO
    def validate_roles(roles)
      roles_array = Array(roles)

      return roles_array if roles_array.empty? || roles_array.all? do |role|
        role.is_a?(Symbol) && role.match?(Role::NAME_REGEX)
      end

      raise(
        InvalidArgumentError,
        "Role names must be Symbols and may only contain lowercase letters, numbers and underscores"
      )
    end

    # TODO
    def validate_custom_rule(custom)
      return custom if custom.nil? || custom.is_a?(Symbol) || custom.is_a?(Proc)

      raise InvalidArgumentError, "Custom rule must be a Symbol or a Proc"
    end
  end
end
