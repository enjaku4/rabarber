# frozen_string_literal: true

class AllAccessController < ApplicationController
  grant_access

  def quux = head(:ok)
end
