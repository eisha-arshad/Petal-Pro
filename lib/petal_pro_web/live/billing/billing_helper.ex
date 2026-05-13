defmodule PetalProWeb.BillingHelper do
  @moduledoc false

  alias PetalPro.Billing.Meters
  alias PetalPro.Billing.Subscriptions
  alias PetalPro.Billing.Subscriptions.Subscription

  @billing_provider Application.compile_env(:petal_pro, :billing_provider)

  def fetch_subscription(nil), do: nil

  def fetch_subscription(subscription) do
    {:ok, provider_subscription} =
      @billing_provider.retrieve_subscription(subscription.provider_subscription_id)

    {:ok, provider_product} =
      provider_subscription
      |> @billing_provider.get_subscription_product()
      |> @billing_provider.retrieve_product()

    %{
      subscription_id: subscription.id,
      provider_subscription_id: provider_subscription.id,
      trialing: provider_subscription.status == "trialing",
      metered: @billing_provider.get_subscription_per_unit(provider_subscription) != nil,
      price: @billing_provider.get_subscription_price(provider_subscription),
      per_unit: @billing_provider.get_subscription_per_unit(provider_subscription),
      currency: provider_subscription.currency,
      cycle: @billing_provider.get_subscription_cycle(provider_subscription),
      next_charge_date: @billing_provider.get_subscription_next_charge(provider_subscription),
      product_name: provider_product.name
    }
  end

  def fetch_latest_invoice(nil), do: nil

  def fetch_latest_invoice(subscription) do
    {:ok, provider_latest_invoice} =
      @billing_provider.retrieve_latest_invoice(subscription.provider_subscription_id)

    %{
      amount: @billing_provider.get_invoice_amount(provider_latest_invoice),
      currency: provider_latest_invoice.currency,
      period_start: @billing_provider.get_invoice_period_start(provider_latest_invoice),
      period_end: @billing_provider.get_invoice_period_end(provider_latest_invoice)
    }
  end

  def fetch_upcoming_invoice(nil), do: nil

  def fetch_upcoming_invoice(subscription) do
    {:ok, provider_upcoming_invoice} =
      @billing_provider.retrieve_upcoming_invoice(subscription.provider_subscription_id)

    %{
      amount: @billing_provider.get_upcoming_amount(provider_upcoming_invoice),
      currency: provider_upcoming_invoice.currency,
      period_start: @billing_provider.get_invoice_period_start(provider_upcoming_invoice)
    }
  end

  def get_meter_summaries(nil, _upcoming_invoice), do: nil
  def get_meter_summaries(_provider_subscription, nil), do: nil
  def get_meter_summaries(%{metered: false}, _upcoming_invoice), do: nil

  def get_meter_summaries(provider_subscription, upcoming_invoice) do
    Meters.list_meter_ids()
    |> Meters.get_meter_summaries(
      provider_subscription.subscription_id,
      upcoming_invoice.period_start,
      DateTime.utc_now(),
      :by_day
    )
    |> Enum.group_by(
      fn meter_usage -> meter_usage.meter_id end,
      fn meter_usage ->
        quantity = round(meter_usage.quantity)

        %{
          timestamp: meter_usage.timestamp,
          quantity: quantity,
          amount: div(quantity * provider_subscription.price, provider_subscription.per_unit)
        }
      end
    )
    |> Enum.map(fn {meter_id, usage} ->
      meter = Meters.get_meter(meter_id)

      %{
        meter_name: meter.name,
        usage: usage
      }
    end)
  end

  def cancel_subscription(nil), do: {:ok, nil}

  def cancel_subscription(subscription) do
    with {:ok, _provider_subscription} <- @billing_provider.cancel_subscription(subscription.provider_subscription_id),
         %Subscription{} = subscription <- Subscriptions.get_subscription!(subscription.id),
         {:ok, updated_subscription} <- Subscriptions.cancel_subscription(subscription) do
      {:ok, updated_subscription}
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end
end
