defmodule PetalPro.Billing.Providers.Stripe.Services.SyncMeter do
  @moduledoc """
  Service for syncing meter events to Stripe for metered billing.
  Local Database is the source of truth.
  Events should utilize Idempotency Keys to prevent duplicate events.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias PetalPro.Billing.Meters.MeterEvent
  alias PetalPro.Billing.Providers.Stripe.Provider
  alias PetalPro.Repo

  require Logger

  @batch_size Application.compile_env(:petal_pro, [:billing_meters_sync_opts, :batch_size], 500)
  @billing_meters Application.compile_env(:petal_pro, [:billing_meters])
  @meter_event_names Map.new(@billing_meters, &{&1.id, &1.event_name})

  @doc """
  Syncs unsent meter events to Stripe in batches.

  ## Options
    * `:batch_size` - Number of events to process in each batch (default: #{@batch_size})

  ## Returns
    * `:ok` - All events were processed successfully
    * `{:error, operation, reason, changes}` - Processing failed at operation with given reason
  """
  def call(opts \\ []) do
    batch_size = Keyword.get(opts, :batch_size, @batch_size)
    Logger.info("Starting batched meter sync with batch size: #{batch_size}")

    Repo.transaction(fn ->
      MeterEvent
      |> where([e], is_nil(e.sent_at))
      |> order_by([e], e.inserted_at)
      |> lock("FOR UPDATE SKIP LOCKED")
      |> Repo.stream(max_rows: batch_size)
      |> Stream.chunk_every(batch_size)
      |> Enum.reduce_while(:ok, &process_batch/2)
    end)
  end

  defp process_batch(events, _acc) do
    Logger.info("Processing batch of #{length(events)} events")

    events_with_customers = Repo.preload(events, :customer)

    events_with_customers
    |> Enum.group_by(& &1.meter_id)
    |> Map.to_list()
    |> Enum.reduce_while(Multi.new(), &build_batch_multi/2)
    |> Repo.transaction()
    |> case do
      {:ok, _results} ->
        {:cont, :ok}

      {:error, _operation, _reason, _changes} = error ->
        {:halt, error}
    end
  end

  defp build_batch_multi({meter_id, events}, multi) do
    Logger.info("Processing events for meter: #{meter_id}")

    events
    |> Enum.with_index()
    |> Enum.reduce_while({:cont, multi}, &process_event(&1, &2, meter_id))
  end

  defp process_event({event, idx}, {:cont, acc_multi}, meter_id) do
    event_name = @meter_event_names[event.meter_id]

    case sync_event(event, event_name) do
      {:ok, _response} ->
        {:cont, {:cont, mark_event_sent(acc_multi, event, idx)}}

      {:error, %Stripe.Error{code: :invalid_request_error, message: "No such customer:" <> _customer_id}} ->
        handle_missing_customer(acc_multi, event, idx, meter_id)

      {:error, %Stripe.Error{code: :invalid_request_error, message: message}} when is_binary(message) ->
        handle_stripe_error(acc_multi, event, idx, meter_id, message)

      {:error, "Missing event_name"} = error ->
        handle_invalid_meter_id(acc_multi, event, idx, meter_id, error)

      {:error, error} ->
        handle_generic_error(acc_multi, event, meter_id, error)
    end
  end

  defp mark_event_sent(multi, event, idx, error_message \\ nil) do
    attrs = %{sent_at: DateTime.truncate(DateTime.utc_now(), :second)}
    attrs = if error_message, do: Map.put(attrs, :error_message, error_message), else: attrs

    Multi.update(
      multi,
      {:mark_sent, event.id, idx},
      MeterEvent.sent_status_changeset(event, attrs)
    )
  end

  defp handle_missing_customer(multi, event, idx, meter_id) do
    Logger.warning("Customer not found in Stripe for event #{event.id} and meter #{meter_id}")

    {:cont, {:cont, mark_event_sent(multi, event, idx, "Customer not found in Stripe")}}
  end

  defp handle_stripe_error(multi, event, idx, meter_id, message) do
    cond do
      String.contains?(message, ["No such meter", "No active meter found"]) ->
        Logger.warning("Meter not found in Stripe for event #{event.id} and meter #{meter_id}")

        {:cont, {:cont, mark_event_sent(multi, event, idx, "Meter not found in Stripe")}}

      message =~ "An event already exists with identifier" ->
        Logger.info("Event #{event.id} already exists in Stripe for meter #{meter_id}, marking as sent")

        {:cont, {:cont, mark_event_sent(multi, event, idx, "Event already exists in Stripe")}}

      true ->
        {:halt, {:halt, Multi.error(multi, {:stripe_error, event.id}, message)}}
    end
  end

  defp handle_invalid_meter_id(multi, event, idx, meter_id, error) do
    Logger.warning("Invalid meter_id for event #{event.id} and meter #{meter_id}: #{inspect(error)}")

    {:cont, {:cont, mark_event_sent(multi, event, idx, "Missing event_name")}}
  end

  defp handle_generic_error(multi, event, meter_id, error) do
    Logger.warning("Failed to sync event #{event.id} for meter #{meter_id}: #{inspect(error)}")

    {:halt, {:halt, Multi.error(multi, {:stripe_error, event.id}, error)}}
  end

  defp sync_event(_event, nil), do: {:error, "Missing event_name"}

  defp sync_event(event, event_name) do
    params = %{
      event_name: event_name,
      identifier: event.event_id,
      payload: %{
        value: event.quantity,
        stripe_customer_id: event.customer.provider_customer_id
      },
      timestamp: DateTime.to_unix(event.inserted_at)
    }

    case Provider.create_meter_event(params) do
      {:ok, _response} = result ->
        Logger.info("Successfully synced event #{event.id}")
        result

      {:error, _reason} = error ->
        error
    end
  end
end
