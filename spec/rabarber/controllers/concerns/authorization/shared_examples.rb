# frozen_string_literal: true

shared_examples_for "it allows access" do |hash|
  it "allows access" do
    send(hash.keys.first, hash.values.first, params: hash[:params])
    expect(response).to have_http_status(:success)
  end

  it "does not log a warning to the audit trail" do
    expect(Rabarber::Audit::Events::UnauthorizedAttempt).not_to receive(:trigger)
    send(hash.keys.first, hash.values.first, params: hash[:params])
  end
end

shared_examples_for "it does not allow access" do |hash|
  it "does not allow access" do
    send(hash.keys.first, hash.values.first, params: hash[:params])
    expect(response).to redirect_to(DummyApplication.routes.url_helpers.root_path)
  end

  it "logs a warning to the audit trail" do
    allow(Rabarber::Audit::Events::UnauthorizedAttempt).to receive(:trigger).and_call_original
    send(hash.keys.first, hash.values.first, params: hash[:params])
    expect(Rabarber::Audit::Events::UnauthorizedAttempt)
      .to have_received(:trigger).with(
        controller.current_user.presence || an_instance_of(Rabarber::Core::NullRoleable),
        path: request.path, request_method: hash.keys.first.to_s.upcase
      )
  end
end

shared_examples_for "it does not allow access when user must have roles" do |hash|
  before { Rabarber::Configuration.instance.must_have_roles = true }

  it_behaves_like "it does not allow access", hash
end

shared_examples_for "it allows access even when user must have roles" do |hash|
  before { Rabarber::Configuration.instance.must_have_roles = true }

  it_behaves_like "it allows access", hash
end

shared_examples_for "it checks permissions integrity" do |hash|
  subject { send(hash.keys.first, hash.values.first, params: hash[:params]) }

  let(:double) { instance_double(Rabarber::Core::PermissionsIntegrityChecker) }

  before do
    allow(Rabarber::Core::PermissionsIntegrityChecker).to receive(:new).with(controller.class).and_return(double)
    allow(Rails.configuration).to receive(:eager_load).and_return(is_eager_load_enabled)
  end

  context "when eager loading is disabled" do
    let(:is_eager_load_enabled) { false }

    it "runs Rabarber::Core::PermissionsIntegrityChecker" do
      expect(double).to receive(:run!)
      subject
    end
  end

  context "when eager loading is enabled" do
    let(:is_eager_load_enabled) { true }

    it "does not run Rabarber::Core::PermissionsIntegrityChecker" do
      expect(double).not_to receive(:run!)
      subject
    end
  end
end

shared_examples_for "it does not check permissions integrity whatsoever" do |hash|
  [true, false].each do |is_eager_load_enabled|
    context "when eager loading is #{is_eager_load_enabled ? "enabled" : "disabled"}" do
      it "does not run Rabarber::Core::PermissionsIntegrityChecker" do
        expect_any_instance_of(Rabarber::Core::PermissionsIntegrityChecker).not_to receive(:run!)
        send(hash.keys.first, hash.values.first, params: hash[:params])
      end
    end
  end
end
