# frozen_string_literal: true

RSpec.describe Rabarber::Logger do
  describe ".log" do
    it "logs the message using Rails.logger" do
      expect(Rails.logger).to receive(:tagged).with("Rabarber") do |&block|
        expect(Rails.logger).to receive(:log).with("foo")
        block.call
      end
      described_class.log(:log, "foo")
    end
  end
end
