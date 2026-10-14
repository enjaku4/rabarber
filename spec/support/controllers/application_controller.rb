# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  with_authorization
end
