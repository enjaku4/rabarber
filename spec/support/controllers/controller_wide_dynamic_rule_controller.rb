# frozen_string_literal: true

class ControllerWideDynamicRuleController < ApplicationController
  grant_access if: :foo?

  private

  def foo?
    true
  end
end
