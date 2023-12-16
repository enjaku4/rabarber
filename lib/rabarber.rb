# frozen_string_literal: true

require_relative "rabarber/version"
require_relative "rabarber/configuration"

require "active_record"
require "active_support"

require_relative "rabarber/controllers/concerns/authorization"

require_relative "rabarber/helpers/helpers"

require_relative "rabarber/models/role"
require_relative "rabarber/models/concerns/has_roles"

require_relative "rabarber/permissions"

module Rabarber
  module_function

  def configure
    yield(Configuration.instance)
  end

  class Error < StandardError; end
end
