# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  subject { described_class.initializers.detect { |i| i.name == "rabarber.after_initialize" }.run(DummyApplication) }

  context "when the roles table exists" do
    before { allow(Rabarber::Role).to receive(:table_exists?).and_return(true) }

    it "checks the actions and roles" do
      expect(Rabarber::Missing::Actions).to receive_message_chain(:new, :handle)
      expect(Rabarber::Missing::Roles).to receive_message_chain(:new, :handle)
      subject
    end
  end

  context "when the roles table does not exist" do
    before { allow(Rabarber::Role).to receive(:table_exists?).and_return(false) }

    it "checks the actions" do
      expect(Rabarber::Missing::Actions).to receive_message_chain(:new, :handle)
      subject
    end

    it "does not check the roles" do
      expect(Rabarber::Missing::Roles).not_to receive(:new)
      expect_any_instance_of(Rabarber::Missing::Roles).not_to receive(:handle)
      subject
    end
  end
end
