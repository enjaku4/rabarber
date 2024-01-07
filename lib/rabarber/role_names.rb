# frozen_string_literal: true

module Rabarber
  module RoleNames
    module_function

    REGEX = /\A[a-z0-9_]+\z/

    def pre_process(role_names)
      return role_names.map(&:to_sym) if role_names.all? do |role_name|
        (role_name.is_a?(Symbol) || role_name.is_a?(String)) && role_name.to_s.match?(REGEX)
      end

      raise(
        InvalidArgumentError,
        "Role names must be Symbols or Strings and may only contain lowercase letters, numbers and underscores"
      )
    end
  end
end
