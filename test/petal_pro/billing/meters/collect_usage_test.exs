defmodule PetalPro.Billing.Meters.CollectMeterEventsTest do
  use PetalPro.DataCase, async: false

  import ExUnit.CaptureLog
  import PetalPro.BillingFixtures

  alias PetalPro.Billing.Meters.CollectMeterEvents
  alias PetalPro.Billing.Meters.MeterEvent
  alias PetalPro.Repo

  # Uncomment GenServer in application.ex to activate
  @moduletag skip: !Process.whereis(CollectMeterEvents)

  setup do
    # Set up shared database connection mode for this test
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "CollectMeterEvents" do
    test "enqueue_meter_event/5 creates a meter event" do
      subscription = subscription_fixture()
      metadata = %{"type" => "api_call"}

      CollectMeterEvents.enqueue_meter_event("mtr_123", subscription.billing_customer_id, subscription.id, 42, metadata)

      # Give the async operation time to complete
      Process.sleep(100)

      # Query the database to verify the event was created
      meter_event = Repo.get_by(MeterEvent, meter_id: "mtr_123")
      assert meter_event
      assert meter_event.quantity == 42
      assert meter_event.metadata == metadata
      assert meter_event.billing_customer_id == subscription.billing_customer_id
      assert meter_event.billing_subscription_id == subscription.id
      # Verify event_id is present
      assert meter_event.event_id
    end

    test "enqueue_meter_event/5 with default metadata" do
      subscription = subscription_fixture()

      CollectMeterEvents.enqueue_meter_event("mtr_123", subscription.billing_customer_id, subscription.id, 42)

      # Give the async operation time to complete
      Process.sleep(100)

      meter_event = Repo.get_by(MeterEvent, meter_id: "mtr_123")
      assert meter_event
      assert meter_event.quantity == 42
      assert meter_event.metadata == %{}
      assert meter_event.billing_customer_id == subscription.billing_customer_id
      assert meter_event.billing_subscription_id == subscription.id
      # Verify event_id is present
      assert meter_event.event_id
    end

    test "multiple concurrent meter events" do
      subscription = subscription_fixture()
      count = 10

      # Enqueue multiple events concurrently
      Enum.each(1..count, fn i ->
        CollectMeterEvents.enqueue_meter_event("mtr_123", subscription.billing_customer_id, subscription.id, i, %{
          "index" => i
        })
      end)

      # Give all async operations time to complete
      Process.sleep(200)

      # Verify all events were created
      events = Repo.all(from m in MeterEvent, where: m.billing_customer_id == ^subscription.billing_customer_id)
      assert length(events) == count

      # Verify the quantities and metadata were correctly saved
      quantities = events |> Enum.map(& &1.quantity) |> Enum.sort()
      assert quantities == Enum.to_list(1..count)

      metadata_indices = events |> Enum.map(& &1.metadata["index"]) |> Enum.sort()
      assert metadata_indices == Enum.to_list(1..count)
    end

    test "logs errors for invalid meter events" do
      subscription = subscription_fixture()

      # Test with invalid meter_id (should cause validation error and be logged)
      log_output =
        capture_log(fn ->
          CollectMeterEvents.enqueue_meter_event("invalid_meter", subscription.billing_customer_id, subscription.id, 1)

          # Give the async operation time to complete
          Process.sleep(200)
        end)

      # Verify error was logged
      assert log_output =~ "Failed to insert meter event for meter invalid_meter"

      # Verify no meter event was created
      meter_event = Repo.get_by(MeterEvent, meter_id: "invalid_meter")
      refute meter_event
    end
  end
end
