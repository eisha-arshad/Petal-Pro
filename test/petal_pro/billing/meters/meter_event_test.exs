defmodule PetalPro.Billing.Meters.MeterEventTest do
  use PetalPro.DataCase, async: true

  import PetalPro.BillingFixtures

  alias PetalPro.Billing.Meters.MeterEvent

  describe "meter_event" do
    test "changeset with valid attributes" do
      subscription = subscription_fixture()

      valid_attrs = %{
        meter_id: "mtr_123",
        event_id: "event_123",
        quantity: 42,
        metadata: %{"type" => "api_call"},
        billing_customer_id: subscription.billing_customer_id,
        billing_subscription_id: subscription.id
      }

      changeset = MeterEvent.changeset(%MeterEvent{}, valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = MeterEvent.changeset(%MeterEvent{}, %{})
      refute changeset.valid?

      assert get_field(changeset, :quantity) == 1
      assert "can't be blank" in errors_on(changeset).meter_id
      assert "can't be blank" in errors_on(changeset).event_id
      assert "can't be blank" in errors_on(changeset).billing_customer_id
      assert "can't be blank" in errors_on(changeset).billing_subscription_id
    end

    test "changeset with invalid meter_id" do
      subscription = subscription_fixture()

      attrs = %{
        meter_id: "invalid_id",
        event_id: "event_123",
        quantity: 1,
        billing_customer_id: subscription.billing_customer_id,
        billing_subscription_id: subscription.id
      }

      changeset = MeterEvent.changeset(%MeterEvent{}, attrs)
      refute changeset.valid?
      assert "invalid meter id" in errors_on(changeset).meter_id
    end

    test "changeset enforces positive quantity" do
      subscription = subscription_fixture()

      attrs = %{
        meter_id: "mtr_123",
        event_id: "event_123",
        quantity: 0,
        billing_customer_id: subscription.billing_customer_id,
        billing_subscription_id: subscription.id
      }

      changeset = MeterEvent.changeset(%MeterEvent{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).quantity

      attrs = %{
        meter_id: "mtr_123",
        event_id: "event_123",
        quantity: -1,
        billing_customer_id: subscription.billing_customer_id,
        billing_subscription_id: subscription.id
      }

      changeset = MeterEvent.changeset(%MeterEvent{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).quantity
    end

    test "creates meter event with valid data" do
      subscription = subscription_fixture()

      valid_attrs = %{
        meter_id: "mtr_123",
        event_id: "event_123",
        quantity: 42,
        metadata: %{"type" => "api_call"},
        billing_customer_id: subscription.billing_customer_id,
        billing_subscription_id: subscription.id
      }

      assert {:ok, %MeterEvent{} = meter_event} =
               %MeterEvent{}
               |> MeterEvent.changeset(valid_attrs)
               |> Repo.insert()

      assert meter_event.quantity == 42
      assert meter_event.metadata == %{"type" => "api_call"}
      assert meter_event.meter_id == "mtr_123"
      assert meter_event.event_id == "event_123"
      assert meter_event.billing_customer_id == subscription.billing_customer_id
      assert meter_event.billing_subscription_id == subscription.id
    end

    test "sent_status_changeset updates sent_at and error_message" do
      subscription = subscription_fixture()

      meter_event =
        meter_event_fixture(%{
          event_id: "event_123",
          billing_customer_id: subscription.billing_customer_id,
          billing_subscription_id: subscription.id
        })

      sent_at = DateTime.truncate(DateTime.utc_now(), :second)

      attrs = %{
        sent_at: sent_at,
        error_message: "test error"
      }

      changeset = MeterEvent.sent_status_changeset(meter_event, attrs)
      assert changeset.valid?
      assert {:ok, updated_event} = Repo.update(changeset)
      assert updated_event.sent_at == sent_at
      assert updated_event.error_message == "test error"
    end

    test "mark_as_unsent_changeset clears sent_at and error_message" do
      subscription = subscription_fixture()
      sent_at = DateTime.truncate(DateTime.utc_now(), :second)

      meter_event =
        meter_event_fixture(%{
          event_id: "event_123",
          billing_customer_id: subscription.billing_customer_id,
          billing_subscription_id: subscription.id,
          sent_at: sent_at,
          error_message: "test error"
        })

      changeset = MeterEvent.mark_as_unsent_changeset(meter_event)
      assert changeset.valid?
      assert {:ok, updated_event} = Repo.update(changeset)
      assert is_nil(updated_event.sent_at)
      assert is_nil(updated_event.error_message)
    end
  end
end
