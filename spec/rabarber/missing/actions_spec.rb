# frozen_string_literal: true

RSpec.describe Rabarber::Missing::Actions do
  subject { described_class.new(controller).handle }

  let(:callable_double) { instance_double(Proc) }

  before { allow(Rabarber::Configuration.instance).to receive(:when_actions_missing).and_return(callable_double) }

  after { Rabarber::Core::Permissions.action_rules.delete(DummyAuthController) }

  context "when controller is not specified" do
    let(:controller) { nil }

    context "when action is missing" do
      before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:admin], nil, nil) }

      it "calls configuration" do
        expect(callable_double).to receive(:call).with([:index], { controller: DummyAuthController })
        subject
      end
    end

    context "when action is not missing" do
      it "does not call configuration" do
        expect(callable_double).not_to receive(:call)
        subject
      end
    end
  end

  context "when controller is specified" do
    let(:controller) { DummyAuthController }

    context "when action is missing" do
      before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:admin], nil, nil) }

      it "calls configuration" do
        expect(callable_double).to receive(:call).with([:index], { controller: DummyAuthController })
        subject
      end
    end

    context "when action is not missing" do
      it "does not call configuration" do
        expect(callable_double).not_to receive(:call)
        subject
      end
    end

    context "when action is missing in another controller" do
      before { Rabarber::Core::Permissions.add(DummyController, :non_existent, [:admin], nil, nil) }

      after { Rabarber::Core::Permissions.action_rules[DummyController].pop }

      it "does not call configuration" do
        expect(callable_double).not_to receive(:call)
        subject
      end
    end
  end
end
