# frozen_string_literal: true

class User < ActiveRecord::Base
  include Rabarber::HasRoles
end

class Client < ActiveRecord::Base
end
