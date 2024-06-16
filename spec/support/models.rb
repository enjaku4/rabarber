# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class User < ApplicationRecord
  include Rabarber::HasRoles
end

class Client < ApplicationRecord; end

class Project < ApplicationRecord; end
