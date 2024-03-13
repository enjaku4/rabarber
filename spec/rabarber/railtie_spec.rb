# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  subject { described_class.initializers.detect { |i| i.name == "rabarber.after_initialize" }.run(DummyApplication) }

  it "checks the actions" do
    expect(Rabarber::Missing::Actions).to receive_message_chain(:new, :handle)
    subject
  end
end
