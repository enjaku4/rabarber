# frozen_string_literal: true

module Rabarber
  module Inputs
    class Boolean < Rabarber::Inputs::Base
      private

      def processor = -> { @value == true || @value == false ? @value : raise_error }
    end
  end
end
