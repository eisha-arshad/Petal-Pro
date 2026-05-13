defmodule PetalPro.BillingFixtures do
  @moduledoc false
  import PetalPro.AccountsFixtures

  alias PetalPro.Billing.Customers
  alias PetalPro.Billing.Meters.MeterEvent
  alias PetalPro.Billing.Subscriptions
  alias PetalPro.Repo

  def billing_customer_fixture(attrs \\ %{}) do
    user_id = attrs[:user_id] || confirmed_user_fixture().id
    source = attrs[:source] || :user
    provider_customer_id = attrs[:provider_customer_id] || "cus_PFDXVnCJHqastp"

    attrs =
      Enum.into(attrs, %{
        user_id: user_id,
        provider: "stripe",
        provider_customer_id: provider_customer_id,
        email: "petal_pro_test_user@example.com"
      })

    {:ok, customer} = Customers.create_customer_by_source(source, attrs)

    customer
  end

  def subscription_fixture(attrs \\ %{}) do
    billing_customer_id = attrs[:billing_customer_id] || billing_customer_fixture().id
    provider_subscription_id = attrs[:provider_subscription_id] || "sub_1RJX2hIWVkWpNCp7ztXBM8Cl"

    attrs =
      Enum.into(attrs, %{
        billing_customer_id: billing_customer_id
      })

    %{
      status: "active",
      plan_id: "stripe-test-plan-a-monthly",
      current_period_start: DateTime.utc_now(),
      provider_subscription_id: provider_subscription_id,
      provider_subscription_items: [
        %{
          price_id: "price_1OQj8pIWVkWpNCp74VstFtnd",
          product_id: "prod_PFDZyFfhgGUNOg"
        }
      ]
    }
    |> Map.merge(attrs)
    |> Subscriptions.create_subscription!()
  end

  def metered_subscription_fixture(attrs \\ %{}) do
    subscription_fixture(
      Map.merge(
        %{
          provider_subscription_id: "sub_1RWB09IWVkWpNCp7q9RhQRt2",
          provider_subscription_items: [
            %{
              price_id: "price_1REKZxIWVkWpNCp7Otf1hyEx",
              product_id: "prod_S8bnyI5qmG5mEz",
              metered: true,
              unit_amount: 500
            }
          ]
        },
        attrs
      )
    )
  end

  def valid_meter_event_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      meter_id: "mtr_123",
      event_id: "event_123",
      quantity: 1,
      metadata: %{"type" => "test_event"}
    })
  end

  def meter_event_fixture(attrs \\ %{}) do
    merged_attrs = Map.merge(valid_meter_event_attributes(), attrs)

    {:ok, meter_event} =
      %MeterEvent{}
      |> MeterEvent.changeset(merged_attrs)
      |> Repo.insert()

    sent_at = Map.get(attrs, :sent_at)

    maybe_update_sent_at(meter_event, sent_at)
  end

  defp maybe_update_sent_at(meter_event, nil), do: meter_event

  defp maybe_update_sent_at(meter_event, sent_at) do
    {:ok, meter_event} =
      meter_event
      |> MeterEvent.sent_status_changeset(%{sent_at: sent_at})
      |> Repo.update()

    meter_event
  end

  def bulk_meter_events_fixture(count, attrs \\ %{}) do
    billing_customer = attrs[:billing_customer] || billing_customer_fixture()
    base_attrs = Map.put(attrs, :billing_customer_id, billing_customer.id)

    Enum.map(1..count, fn _ ->
      meter_event_fixture(base_attrs)
    end)
  end
end
