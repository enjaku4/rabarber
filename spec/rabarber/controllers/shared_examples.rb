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

  it "does not allow access with a different format" do
    send(hash.keys.first, hash.values.first, params: hash[:params], format: :json)
    expect(response).to have_http_status(:forbidden)
  end
end

shared_examples_for "it raises an error on nil current_user" do |hash|
  it "raises an error" do
    expect { send(hash.keys.first, hash.values.first, params: hash[:params]) }
      .to raise_error(Rabarber::Error, "Expected `current_user` to return an instance of User, got nil")
  end
end
