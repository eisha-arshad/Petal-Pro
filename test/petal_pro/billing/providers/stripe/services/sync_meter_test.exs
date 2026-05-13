defmodule PetalPro.Billing.Providers.Stripe.Services.SyncMeterTest do
  use PetalPro.DataCase

  import PetalPro.BillingFixtures

  alias PetalPro.Billing.Meters.MeterEvent
  alias PetalPro.Billing.Providers.Stripe.Services.SyncMeter
  alias PetalPro.Repo

  @moduletag :capture_log

  describe "call/0" do
    setup do
      billing_customer = billing_customer_fixture(provider_customer_id: "cus_PFDXVnCJHqastp")
      subscription = subscription_fixture(billing_customer_id: billing_customer.id)
      %{billing_customer: billing_customer, subscription: subscription}
    end

    test "syncs unsent meter events to Stripe", %{billing_customer: billing_customer, subscription: subscription} do
      use_cassette "PetalPro.Billing.Providers.Stripe.Services.SyncMeter.call",
        match_requests_on: [:method, :url, :body] do
        events =
          bulk_meter_events_fixture(5, %{
            billing_customer: billing_customer,
            billing_subscription_id: subscription.id,
            meter_id: "mtr_234",
            event_id: MeterEvent.generate_event_id()
          })

        assert {:ok, :ok} = SyncMeter.call()

        # Verify all events were marked as sent
        Enum.each(events, fn event ->
          updated_event = Repo.get!(MeterEvent, event.id)
          assert not is_nil(updated_event.sent_at)
          assert is_nil(updated_event.error_message)
        end)
      end
    end

    test "handles nonexistent meter id", %{billing_customer: billing_customer, subscription: subscription} do
      use_cassette "PetalPro.Billing.Providers.Stripe.Services.SyncMeter.call_error_meter_id",
        match_requests_on: [:method, :url, :body] do
        event =
          meter_event_fixture(%{
            billing_customer_id: billing_customer.id,
            billing_subscription_id: subscription.id,
            meter_id: "mtr_nonexistent",
            event_id: "event_nonexistent",
            quantity: 1
          })

        assert {:ok, :ok} = SyncMeter.call()

        updated_event = Repo.get!(MeterEvent, event.id)
        assert not is_nil(updated_event.sent_at)
        assert updated_event.error_message == "Meter not found in Stripe"
      end
    end

    test "handles invalid meter id not in configuration", %{
      billing_customer: billing_customer,
      subscription: subscription
    } do
      # Create an event with a meter_id that doesn't exist in the configuration
      # We need to bypass the changeset validation to create this invalid event
      {:ok, event} =
        %MeterEvent{}
        |> Ecto.Changeset.change(%{
          meter_id: "mtr_invalid_config",
          event_id: "event_invalid_config",
          quantity: 1,
          billing_customer_id: billing_customer.id,
          billing_subscription_id: subscription.id
        })
        |> Repo.insert()

      assert {:ok, :ok} = SyncMeter.call()

      updated_event = Repo.get!(MeterEvent, event.id)
      assert not is_nil(updated_event.sent_at)
      assert updated_event.error_message == "Missing event_name"
    end

    test "handles missing customers gracefully", %{subscription: subscription} do
      use_cassette "PetalPro.Billing.Providers.Stripe.Services.SyncMeter.call_missing_customer",
        match_requests_on: [:method, :url, :body] do
        # New unknown billing customer
        billing_customer =
          billing_customer_fixture(provider_customer_id: "cus_does_not_exist")

        event =
          meter_event_fixture(%{
            billing_customer_id: billing_customer.id,
            billing_subscription_id: subscription.id,
            meter_id: "mtr_234",
            event_id: MeterEvent.generate_event_id(),
            quantity: 1
          })

        assert {:ok, :ok} = SyncMeter.call()

        updated_event = Repo.get!(MeterEvent, event.id)
        assert not is_nil(updated_event.sent_at)

        assert updated_event.error_message == "Customer not found in Stripe"
      end
    end

    test "processes events in batches", %{billing_customer: billing_customer, subscription: subscription} do
      use_cassette "PetalPro.Billing.Providers.Stripe.Services.SyncMeter.call_batch_processing",
        match_requests_on: [:method, :url, :body] do
        # Create more events than the default batch size to test batching
        events =
          bulk_meter_events_fixture(5, %{
            billing_customer: billing_customer,
            billing_subscription_id: subscription.id,
            meter_id: "mtr_234",
            event_id: MeterEvent.generate_event_id()
          })

        assert {:ok, :ok} = SyncMeter.call(batch_size: 2)

        # Verify all events were processed despite batching
        Enum.each(events, fn event ->
          updated_event = Repo.get!(MeterEvent, event.id)
          assert not is_nil(updated_event.sent_at)
          assert is_nil(updated_event.error_message)
        end)
      end
    end

    test "handles duplicate event syncs idempotently", %{billing_customer: billing_customer, subscription: subscription} do
      # Create initial event
      event =
        meter_event_fixture(%{
          billing_customer_id: billing_customer.id,
          billing_subscription_id: subscription.id,
          meter_id: "mtr_234",
          event_id: MeterEvent.generate_event_id(),
          quantity: 1
        })

      id = event.id

      # First sync
      use_cassette "PetalPro.Billing.Providers.Stripe.Services.SyncMeter.call_initial_sync",
        match_requests_on: [:method, :url, :body] do
        assert {:ok, :ok} = SyncMeter.call()
      end

      # Force a new transaction to ensure the first one is committed
      Repo.checkout(fn ->
        # Manually mark event as unsent in a separate transaction
        {:ok, _} =
          MeterEvent
          |> Repo.get!(id)
          |> MeterEvent.mark_as_unsent_changeset()
          |> Repo.update()

        # Verify the event was marked as unsent
        updated_event = Repo.get!(MeterEvent, id)
        assert is_nil(updated_event.sent_at)

        # Second sync with same event
        use_cassette "PetalPro.Billing.Providers.Stripe.Services.SyncMeter.call_duplicate_sync",
          match_requests_on: [:method, :url, :body] do
          assert {:ok, :ok} = SyncMeter.call()

          # Verify the event was marked as sent again
          final_event = Repo.get!(MeterEvent, id)
          assert not is_nil(final_event.sent_at)
          assert is_nil(final_event.error_message)
        end
      end)
    end
  end
end
