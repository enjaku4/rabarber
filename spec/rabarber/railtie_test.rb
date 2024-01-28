# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  it "calls the after_initialize methods" do
    expect(Rabarber::Missing::Actions).to receive_message_chain(:new, :handle)
    expect(Rabarber::Missing::Roles).to receive_message_chain(:new, :handle)
    described_class.initializers.detect { |i| i.name == "rabarber.after_initialize" }.run(DummyApplication)
  end
end
