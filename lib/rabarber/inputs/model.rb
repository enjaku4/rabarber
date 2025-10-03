# frozen_string_literal: true

module Rabarber
  module Inputs
    class Model < Rabarber::Inputs::Base
      private

      def type = self.class::Strict::Class.constructor { _1.try(:safe_constantize) }.constrained(lt: ActiveRecord::Base)
    end
  end
end
