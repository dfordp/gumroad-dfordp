# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::PayoutsController do
  let(:user) { create(:user) }
  let(:token) { create(:access_token, resource_owner_id: user.id, scopes: "payout_read") }
  let!(:payout) { create(:payout, user: user, amount_cents: 15000, currency: "USD", status: "completed", processed_at: 1.day.ago) }

  describe "GET index" do
    it "returns payouts" do
      request.headers["Authorization"] = "Bearer #{token.token}"
      get :index, format: :json

      expect(response).to be_successful
      body = JSON.parse(response.body)
      expect(body["success"]).to eq(true)
      expect(body["payouts"].length).to eq(1)
      expect(body["payouts"][0]["id"]).to eq(payout.external_id)
      expect(body["payouts"][0]["amount"]).to eq(payout.amount_display)
      expect(body["payouts"][0]["currency"]).to eq(payout.currency)
      expect(body["payouts"][0]["status"]).to eq(payout.status)
      expect(body["payouts"][0]["payment_processor"]).to eq(payout.payment_processor)
    end

    it "returns unauthorized without token" do
      get :index, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns forbidden without payout_read scope" do
      token = create(:access_token, resource_owner_id: user.id, scopes: "")
      request.headers["Authorization"] = "Bearer #{token.token}"
      get :index, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "paginates results" do
      create_list(:payout, 25, user: user)
      request.headers["Authorization"] = "Bearer #{token.token}"

      get :index, params: { page: 1 }, format: :json
      expect(JSON.parse(response.body)["payouts"].length).to eq(20)

      get :index, params: { page: 2 }, format: :json
      expect(JSON.parse(response.body)["payouts"].length).to eq(6)
    end
  end

  describe "GET show" do
    it "returns a payout" do
      request.headers["Authorization"] = "Bearer #{token.token}"
      get :show, params:
