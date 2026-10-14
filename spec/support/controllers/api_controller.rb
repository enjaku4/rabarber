# frozen_string_literal: true

class ApiController < ActionController::API
  include Rabarber::Authorization

  with_authorization

  grant_access action: :api_action, roles: :client
  def api_action = head(:ok)
end
