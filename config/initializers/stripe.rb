Rails.configuration.stripe = {
  :publishable_key => ENV['STRIPE_PUBLISHABLE_KEY'],
  :secret_key      => ENV['STRIPE_SECRET_KEY']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]

# Stripe Events Handler
StripeEvent.configure do |events|
  events.subscribe 'invoice.created' do |event|
    invoice = StripeInvoice.new(event.id)
    invoice.process_invoice_items
  end
end