# frozen_string_literal: true

shared_examples_for "it allows access" do |hash|
  it "allows access" do
    send(hash.keys.first, hash.values.first, params: hash[:params])
    expect(response).to have_http_status(:success)
  end
end

shared_examples_for "it does not allow access" do |hash|
  it "does not allow access" do
    send(hash.keys.first, hash.values.first, params: hash[:params])
    expect(response).to redirect_to(DummyApplication.routes.url_helpers.root_path)
  end
end

shared_examples_for "it checks permissions integrity" do |hash|
  subject { send(hash.keys.first, hash.values.first, params: hash[:params]) }

  let(:double) { instance_double(Rabarber::Core::IntegrityChecker) }

  before do
    allow(Rabarber::Core::IntegrityChecker).to receive(:new).with(controller.class).and_return(double)
    allow(Rails.configuration).to receive(:eager_load).and_return(is_eager_load_enabled)
  end

  context "when eager loading is disabled" do
    let(:is_eager_load_enabled) { false }

    it "runs Rabarber::Core::IntegrityChecker" do
      expect(double).to receive(:run!)
      subject
    end
  end

  context "when eager loading is enabled" do
    let(:is_eager_load_enabled) { true }

    it "does not run Rabarber::Core::IntegrityChecker" do
      expect(double).not_to receive(:run!)
      subject
    end
  end
end

shared_examples_for "it does not check permissions integrity" do |hash|
  [true, false].each do |is_eager_load_enabled|
    context "when eager loading is #{is_eager_load_enabled ? "enabled" : "disabled"}" do
      it "does not run Rabarber::Core::IntegrityChecker" do
        expect_any_instance_of(Rabarber::Core::IntegrityChecker).not_to receive(:run!)
        send(hash.keys.first, hash.values.first, params: hash[:params])
      end
    end
  end
end

shared_examples_for "it raises an error on nil current_user" do |hash|
  it "raises an error" do
    expect { send(hash.keys.first, hash.values.first, params: hash[:params]) }
      .to raise_error(Rabarber::Error, "Expected an instance of User from current_user method, but got nil")
  end
end
