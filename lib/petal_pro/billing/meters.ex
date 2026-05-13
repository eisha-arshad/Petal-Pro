defmodule PetalPro.Billing.Meters do
  @moduledoc """
  High level API for managing billing meters and collecting meter events.
  """

  import Ecto.Query, only: [from: 2]

  alias PetalPro.Billing.Meters.CollectMeterEvents
  alias PetalPro.Billing.Meters.MeterEvent
  alias PetalPro.Repo

  @billing_meters Application.compile_env(:petal_pro, [:billing_meters])

  @doc """
  Returns list of all configured billing meters.

  ## Examples

      iex> Meters.list_meters()
      [%{id: "api_calls", ...}, %{id: "storage_gb", ...}]
  """
  def list_meters do
    @billing_meters
  end

  @doc """
  Returns list of ids for all configured billing meters.

  ## Examples

      iex> Meters.list_meter_ids()
      ["api_calls", "storage_gb", ...]
  """
  def list_meter_ids do
    Enum.map(@billing_meters, & &1.id)
  end

  @doc """
  Gets a meter by ID.

  ## Examples

      iex> Meters.get_meter("mtr_xxx_xxxxx")
      %{id: "mtr_xxx_xxxxx", event_name: "api_calls", ...}

      iex> Meters.get_meter("invalid")
      nil
  """
  def get_meter(meter_id) do
    Enum.find(@billing_meters, &(&1.id == meter_id))
  end

  @doc """
  Gets a meter by event_name.

  ## Examples

      iex> Meters.get_meter_by_event_name("api_meter")
      %{id: "mtr_xxx_xxxxx", event_name: "api_calls", ...}

      iex> Meters.get_meter("invalid")
      nil
  """
  def get_meter_by_event_name(event_name) do
    Enum.find(@billing_meters, &(&1.event_name == event_name))
  end

  @doc """
  Records a meter event for a customer/subscription.
  This is a non-blocking operation that enqueues the event for processing.

  ## Examples

      iex> Meters.record_event("api_calls", customer_id, subscription_id)
      {:ok, :enqueued}

      iex> Meters.record_event("api_calls", customer_id, subscription_id, 5)
      {:ok, :enqueued}

      iex> Meters.record_event("api_calls", customer_id, subscription_id, 1, %{path: "/api/users"})
      {:ok, :enqueued}

      iex> Meters.record_event("invalid_meter", customer_id, subscription_id)
      {:error, :invalid_meter}

      iex> Meters.record_event("api_calls", invalid_customer_id, subscription_id)
      {:error, :invalid_customer}

      iex> Meters.record_event("invalid_meter", customer_id, invalid_subscription_id)
      {:error, :invalid_subscription}
  """
  def record_event(meter_id, customer_id, subscription_id, quantity \\ 1, metadata \\ %{}) do
    with {:ok, _meter} <- validate_meter(meter_id),
         {:ok, _customer} <- validate_customer(customer_id),
         {:ok, _subscription} <- validate_subscription(subscription_id) do
      CollectMeterEvents.enqueue_meter_event(meter_id, customer_id, subscription_id, quantity, metadata)
      {:ok, :enqueued}
    end
  end

  defp validate_meter(meter_id) do
    case get_meter(meter_id) do
      nil -> {:error, :invalid_meter}
      meter -> {:ok, meter}
    end
  end

  defp validate_meters(meter_ids) do
    valid_meters = Enum.map(meter_ids, fn meter_id -> get_meter(meter_id) end)

    if Enum.any?(valid_meters, &is_nil/1) do
      {:error, :invalid_meters}
    else
      {:ok, valid_meters}
    end
  end

  defp validate_customer(customer_id) do
    case PetalPro.Billing.Customers.get_customer_by(%{id: customer_id}) do
      nil -> {:error, :invalid_customer}
      customer -> {:ok, customer}
    end
  end

  defp validate_subscription(subscription_id) do
    case PetalPro.Billing.Subscriptions.get_subscription_by(%{id: subscription_id}) do
      nil -> {:error, :invalid_subscription}
      subscription -> {:ok, subscription}
    end
  end

  @doc """
  Gets a summary of meter events from Stripe for a customer within a specified time range.

  ## Parameters
    * `meter_id` - The ID of the meter to get summaries for
    * `customer_id` - The ID of the customer to get summaries for
    * `start_time` - Unix timestamp for the start of the period
    * `end_time` - Unix timestamp for the end of the period
    * `value_grouping_window` - How to group the values, either `:by_hour` or `:by_day`

  ## Examples

      # Get hourly summary
      iex> Meters.get_meter_summary("api_calls", customer_id, 1711584000, 1711666800, :by_hour)
      {:ok, %{...}}

      # Get daily summary
      iex> Meters.get_meter_summary("api_calls", customer_id, 1711584000, 1711666800, :by_day)
      {:ok, %{...}}

      iex> Meters.get_meter_summary("invalid_meter", customer_id, 1711584000, 1711666800, :by_hour)
      {:error, :invalid_meter}
  """

  def get_meter_summary(meter_id, billing_customer_id, start_time, end_time, value_grouping_window)
      when value_grouping_window in [:by_hour, :by_day] and end_time > start_time do
    with {:ok, _meter} <- validate_meter(meter_id),
         {:ok, customer} <- validate_customer(billing_customer_id) do
      PetalPro.Billing.Providers.Stripe.Provider.get_meter_summary(
        meter_id,
        customer.provider_customer_id,
        start_time,
        end_time,
        value_grouping_window
      )
    end
  end

  @doc """
  Gets a summary of meter events from the database for a subscription within a specified time range.

  ## Parameters
    * `meter_ids` - List of meter IDs to get summaries for
    * `subscription_id` - The ID of the subscription to get summaries for
    * `start_time` - DateTime for the start of the period
    * `end_time` - DateTime for the end of the period
    * `value_grouping_window` - How to group the values, either `:by_hour` or `:by_day`

  ## Returns
    A list of maps with meter usage data, each containing:
    * `meter_id` - The ID of the meter
    * `timestamp` - The timestamp for the grouped data point
    * `quantity` - The sum of quantities for the time period

  ## Examples

      iex> Meters.get_meter_summaries(["api_calls"], subscription_id, ~U[2023-01-01 00:00:00Z], ~U[2023-01-02 00:00:00Z], :by_day)
      [%{meter_id: "api_calls", timestamp: ~U[2023-01-01 00:00:00Z], quantity: 42}]

      iex> Meters.get_meter_summaries(["invalid_meter"], subscription_id, ~U[2023-01-01 00:00:00Z], ~U[2023-01-02 00:00:00Z], :by_hour)
      {:error, :invalid_meters}
  """
  def get_meter_summaries(meter_ids, subscription_id, start_time, end_time, value_grouping_window)
      when value_grouping_window in [:by_hour, :by_day] and end_time > start_time do
    with {:ok, _meters} <- validate_meters(meter_ids),
         {:ok, _subscription} <- validate_subscription(subscription_id) do
      query =
        from meter_event in MeterEvent,
          where: meter_event.billing_subscription_id == ^subscription_id,
          where: meter_event.inserted_at >= ^start_time and meter_event.inserted_at <= ^end_time,
          where: not is_nil(meter_event.sent_at),
          where: is_nil(meter_event.error_message),
          select: %{
            meter_id: meter_event.meter_id,
            timestamp:
              fragment(
                "date_trunc(?, ?) AS truncated_date",
                ^trunc_grouping_window(value_grouping_window),
                meter_event.inserted_at
              ),
            quantity: sum(meter_event.quantity)
          },
          group_by: meter_event.meter_id,
          group_by: fragment("truncated_date"),
          order_by: fragment("truncated_date desc")

      Repo.all(query)
    end
  end

  defp trunc_grouping_window(:by_hour), do: "hour"
  defp trunc_grouping_window(:by_day), do: "day"
end
