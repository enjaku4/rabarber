# frozen_string_literal: true

require "action_view"

class DummyHelper < ActionView::Base
  include Rabarber::Helpers
end
