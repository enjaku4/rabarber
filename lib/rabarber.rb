# frozen_string_literal: true

require_relative "rabarber/version"
require_relative "rabarber/configuration"

require "active_record"
require "active_support"

require_relative "rabarber/input/base"
require_relative "rabarber/input/action"
require_relative "rabarber/input/authorization_context"
require_relative "rabarber/input/context"
require_relative "rabarber/input/dynamic_rule"
require_relative "rabarber/input/role"
require_relative "rabarber/input/roles"
require_relative "rabarber/input/types/ar_model"
require_relative "rabarber/input/types/boolean"
require_relative "rabarber/input/types/proc"
require_relative "rabarber/input/types/symbol"

require_relative "rabarber/core/cache"

require_relative "rabarber/audit/events/base"
require_relative "rabarber/audit/events/roles_assigned"
require_relative "rabarber/audit/events/roles_revoked"
require_relative "rabarber/audit/events/unauthorized_attempt"

require_relative "rabarber/core/roleable"

require_relative "rabarber/controllers/concerns/authorization"
require_relative "rabarber/helpers/helpers"
require_relative "rabarber/models/concerns/has_roles"
require_relative "rabarber/models/role"

require_relative "rabarber/core/permissions"
require_relative "rabarber/core/permissions_integrity_checker"

require_relative "rabarber/railtie"

module Rabarber
  class Error < StandardError; end
  class ConfigurationError < Rabarber::Error; end
  class InvalidArgumentError < Rabarber::Error; end

  def configure
    yield(Rabarber::Configuration.instance)
  end
  module_function :configure
end
