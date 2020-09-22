class PaymentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:pay, :make_payment, :thank]
  layout "user-account"
  include SessionsHelper
  include ApplicationHelper
  require "stripe"

  def pay
    render layout: "bare-bones"
  end

  def thank
    render layout: "bare-bones"
  end

  def make_payment
    begin
      token = create_token(params)
      response = make_custom_payment(params, token)
      redirect_to thank_payment_path
    rescue => error
      flash[:error] = error.message
      redirect_to pay_path
    end
  end

  private

  def create_token(params)
    Stripe::Token.create(
      :card => {
        :number => params["card-number"],
        :exp_month => params["expiry-month"],
        :exp_year => params["expiry-year"],
        :cvc => params["card-cvc"]
      },
    )
  end

  def make_custom_payment(params, token)
    amount = params[:amount].to_f * 100
    Stripe::Charge.create(
      :amount => amount.to_i,
      :currency => "eur",
      :source => token.id,
      :description => "Charge for #{params[:email]}"
    )
  end
end

