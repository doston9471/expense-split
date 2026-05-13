# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Status", type: :request do
  it "returns service metadata" do
    get "/api/v1/status"
    expect(response).to have_http_status(:ok)
    json = response.parsed_body
    expect(json["status"]).to eq("ok")
    expect(json["api_version"]).to eq("v1")
  end
end
