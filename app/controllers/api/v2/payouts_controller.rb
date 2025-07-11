class Api::V2::PayoutsController < Api::V2::BaseController
  before_action :doorkeeper_authorize!
  before_action :set_payout, only: [:show]

  def index
    payouts = current_user.payouts.order(created_at: :desc).page(params[:page]).per(20)
    render json: {
      success: true,
      payouts: payouts.map { |payout| serialize_payout(payout) }
    }
  end

  def show
    render json: {
      success: true,
      payout: serialize_payout(@payout)
    }
  end

  private

  def set_payout
    @payout = current_user.payouts.find_by(external_id: params[:id])
    render json: { success: false, message: "Payout not found" }, status: :not_found unless @payout
  end

  def serialize_payout(payout)
    {
      id: payout.external_id,
      amount: payout.amount_display,
      currency: payout.currency,
      status: payout.status,
      created_at: payout.created_at.iso8601,
      processed_at: payout.processed_at&.iso8601,
      payment_processor: payout.payment_processor
    }
  end
end
