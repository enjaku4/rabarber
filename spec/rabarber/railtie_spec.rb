# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  subject { described_class.initializers.detect { |i| i.name == "rabarber.after_initialize" }.run(DummyApplication) }

  context "when eager_load is true" do
    it "checks the actions" do
      expect(Rabarber::Missing::Actions).to receive_message_chain(:new, :handle)
      subject
    end
  end

  context "when eager_load is false" do
    before { allow(Rails.configuration).to receive(:eager_load).and_return(false) }

    it "does not check the actions" do
      expect(Rabarber::Missing::Actions).not_to receive(:new)
      subject
    end
  end
end
