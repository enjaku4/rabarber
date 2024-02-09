# frozen_string_literal: true

module Rabarber
  module Logger
    module_function

    def log(log_level, message)
      Rails.logger.tagged("Rabarber") { Rails.logger.public_send(log_level, message) }
    end
  end
end
