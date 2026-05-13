defmodule PetalPro.Billing.Providers.Stripe.Provider do
  @moduledoc """
  An interface to the Stripe API.

  Use this instead of StripityStripe directly because it allows you to mock responses in tests (thanks to mox).

  For example:

      alias PetalPro.Billing.Providers.Stripe.Provider

      expect(Provider, :create_checkout_session, fn _ ->
        mocked_session_response()
      end)
  """
  @behaviour PetalPro.Billing.Providers.Stripe.ProviderBehaviour

  import Stripe.Request

  require Logger

  # Window values for meter summaries
  @window_by_hour "hour"
  @window_by_day "day"

  @impl true
  def create_customer(params) do
    Stripe.Customer.create(params)
  end

  @impl true
  def create_portal_session(params) do
    Stripe.BillingPortal.Session.create(params)
  end

  @impl true
  def create_checkout_session(params) do
    Stripe.Checkout.Session.create(params)
  end

  @impl true
  def retrieve_product(stripe_product_id) do
    Stripe.Product.retrieve(stripe_product_id)
  end

  @impl true
  def list_subscriptions(params) do
    Stripe.Subscription.list(params)
  end

  @impl true
  def retrieve_latest_invoice(provider_subscription_id) do
    case Stripe.Invoice.list(%{
           subscription: provider_subscription_id,
           limit: 2
         }) do
      {:ok, invoices} ->
        # Filter out draft invoice (which can happen if one is being created manually)
        invoices.data
        |> Enum.find(fn line -> line.status != "draft" end)
        |> then(fn
          nil -> {:ok, nil}
          line -> Stripe.Invoice.retrieve(line.id)
        end)

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def retrieve_upcoming_invoice(provider_subscription_id) do
    Stripe.Invoice.upcoming(%{subscription: provider_subscription_id})
  end

  @impl true
  def retrieve_subscription(provider_subscription_id) do
    Stripe.Subscription.retrieve(provider_subscription_id)
  end

  @impl true
  def cancel_subscription(id) do
    Stripe.Subscription.cancel(id)
  end

  @doc """
  Metered events are not supported by Stripity Stripe yet, so we need to make a custom request.
  https://github.com/beam-community/stripity-stripe/issues/846
  """
  @impl true
  def create_meter_event(params) do
    Logger.debug("Creating Stripe meter event with params #{inspect(params)}")

    new_request()
    |> put_method(:post)
    |> put_endpoint("/v1/billing/meter_events")
    |> put_params(params)
    |> make_request()
    |> handle_stripe_response()
  end

  @impl true
  def get_meter_summary(meter_id, customer_id, start_time, end_time, value_grouping_window) do
    Logger.debug("Fetching Stripe meter summary for meter #{meter_id}")

    window_value =
      case value_grouping_window do
        :by_hour -> @window_by_hour
        :by_day -> @window_by_day
      end

    params = %{
      customer: customer_id,
      start_time: start_time,
      end_time: end_time,
      value_grouping_window: window_value
    }

    new_request()
    |> put_method(:get)
    |> put_endpoint("/v1/billing/meters/#{meter_id}/event_summaries")
    |> put_params(params)
    |> make_request()
    |> handle_stripe_response()
  end

  defp handle_stripe_response({:ok, body}), do: {:ok, body}

  defp handle_stripe_response({:error, %Stripe.Error{} = error}) do
    Logger.error("Stripe error: #{inspect(error)}")
    {:error, error}
  end

  defp handle_stripe_response(error) do
    Logger.error("Unexpected error in Stripe API call: #{inspect(error)}")
    {:error, error}
  end
end
