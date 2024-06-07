# frozen_string_literal: true

module Rabarber
  module Audit
    module Events
      class UnauthorizedAttempt < Base
        private

        def nil_roleable_allowed?
          true
        end

        def log_level
          :warn
        end

        def message
          "[Unauthorized Attempt] #{identity} | request: #{request_method} '#{path}'"
        end

        def path
          specifics.fetch(:path)
        end

        def request_method
          specifics.fetch(:request_method)
        end
      end
    end
  end
end
