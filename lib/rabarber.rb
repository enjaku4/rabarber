# frozen_string_literal: true

require_relative "rabarber/version"
require_relative "rabarber/configuration"

require "active_record"
require "active_support"

require_relative "rabarber/input/base"
require_relative "rabarber/input/actions"
require_relative "rabarber/input/dynamic_rules"
require_relative "rabarber/input/roles"
require_relative "rabarber/input/types/booleans"
require_relative "rabarber/input/types/procs"
require_relative "rabarber/input/types/symbols"

require_relative "rabarber/missing/base"
require_relative "rabarber/missing/actions"
require_relative "rabarber/missing/roles"

require_relative "rabarber/controllers/concerns/authorization"
require_relative "rabarber/helpers/helpers"
require_relative "rabarber/models/concerns/has_roles"
require_relative "rabarber/models/role"
require_relative "rabarber/permissions"

module Rabarber
  module_function

  class Error < StandardError; end
  class ConfigurationError < Rabarber::Error; end
  class InvalidArgumentError < Rabarber::Error; end

  def configure
    yield(Rabarber::Configuration.instance)
  end

  # TODO

  # class Railtie < Rails::Railtie
  #   initializer "rabarber.after_initialize" do
  #     Rabarber::Missing::Actions.new.handle
  #     Rabarber::Missing::Roles.new.handle
  #   end
  # end
end
