# frozen_string_literal: true

# TODO: implement

RSpec.describe Rabarber::Missing::Actions do
  subject { described_class.new(controller).handle }

  let(:callable_double) { instance_double(Proc) }

  before { allow(Rabarber::Configuration.instance).to receive(:when_actions_missing).and_return(callable_double) }

  context "when controller is not specified" do
    let(:controller) { nil }

    context "when action is missing" do

    end

    context "when action is not missing" do

    end
  end

  context "when controller is specified" do
    let(:controller) { DummyController }

    context "when action is missing" do

    end

    context "when action is not missing" do

    end

    context "when action is missing in another controller" do

    end
  end
end
