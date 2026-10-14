# frozen_string_literal: true

class DummyPagesController < ActionController::Base
  def home = head(:ok)
end
