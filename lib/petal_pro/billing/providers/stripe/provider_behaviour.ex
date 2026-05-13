defmodule PetalPro.Billing.Providers.Stripe.ProviderBehaviour do
  @moduledoc false
  @type params :: map()
  @type id :: Stripe.id()
  @type customer :: Stripe.Customer.t()
  @type session :: Stripe.Checkout.Session.t()
  @type product :: Stripe.Product.t()
  @type subscription :: Stripe.Subscription.t()
  @type invoice :: Stripe.Invoice.t()
  @type error :: Stripe.Error.t()
  @type value_grouping_window :: :by_hour | :by_day

  @callback create_customer(params) :: {:ok, customer} | {:error, error}
  @callback create_portal_session(params) :: {:ok, session} | {:error, error}
  @callback create_checkout_session(params) :: {:ok, session} | {:error, error}
  @callback retrieve_product(id) :: {:ok, product} | {:error, error}
  @callback list_subscriptions(params) :: {:ok, list(subscription)} | {:error, error}
  @callback retrieve_subscription(id) :: {:ok, subscription} | {:error, error}
  @callback cancel_subscription(id) :: {:ok, subscription} | {:error, error}
  @callback retrieve_latest_invoice(id) :: {:ok, invoice} | {:error, error}
  @callback retrieve_upcoming_invoice(id) :: {:ok, invoice} | {:error, error}
  @callback create_meter_event(map()) :: {:ok, map()} | {:error, error}
  @callback get_meter_summary(
              meter_id :: String.t(),
              customer_id :: String.t(),
              start_time :: integer(),
              end_time :: integer(),
              value_grouping_window :: value_grouping_window()
            ) :: {:ok, map()} | {:error, error}
end
