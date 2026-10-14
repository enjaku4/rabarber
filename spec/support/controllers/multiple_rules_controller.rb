# frozen_string_literal: true

class MultipleRulesController < ApplicationController
  grant_access roles: [:maintainer]
  grant_access roles: [:admin, :user], context: Project

  def qux = head(:ok)
end
