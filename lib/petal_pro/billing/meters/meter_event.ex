defmodule PetalPro.Billing.Meters.MeterEvent do
  @moduledoc """
  Schema for billing meter events.
  Represents individual meter events that will be reported to the billing provider.
  """
  use PetalPro.Schema

  @billing_meters Application.compile_env(:petal_pro, [:billing_meters], [])

  # Create lookup map for validation
  @meter_by_id Map.new(@billing_meters, &{&1.id, &1})

  typed_schema "billing_meter_events" do
    field :meter_id, :string
    field :event_id, :string
    field :quantity, :integer, default: 1
    field :metadata, :map, default: %{}
    field :sent_at, :utc_datetime
    field :error_message, :string

    belongs_to :customer, PetalPro.Billing.Customers.Customer, foreign_key: :billing_customer_id
    belongs_to :subscription, PetalPro.Billing.Subscriptions.Subscription, foreign_key: :billing_subscription_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for validating and creating meter events.
  """
  def changeset(meter_event, attrs) do
    attrs = Map.put_new(attrs, :quantity, 1)

    meter_event
    |> cast(attrs, [:meter_id, :event_id, :quantity, :metadata, :billing_customer_id, :billing_subscription_id])
    |> validate_required([:meter_id, :event_id, :quantity, :billing_customer_id, :billing_subscription_id])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_meter_id()
    |> foreign_key_constraint(:billing_customer_id)
    |> foreign_key_constraint(:billing_subscription_id)
  end

  @doc """
  Creates a changeset for updating the sent status and error message.
  """
  def sent_status_changeset(meter_event, attrs) do
    cast(meter_event, attrs, [:sent_at, :error_message])
  end

  @doc """
  Creates a changeset to mark an event as unsent by clearing sent_at and error_message.
  """
  def mark_as_unsent_changeset(meter_event) do
    change(meter_event, sent_at: nil, error_message: nil)
  end

  defp validate_meter_id(changeset) do
    case get_field(changeset, :meter_id) do
      nil ->
        changeset

      meter_id ->
        case Map.get(@meter_by_id, meter_id) do
          nil -> add_error(changeset, :meter_id, "invalid meter id")
          _meter -> changeset
        end
    end
  end

  @doc """
  Generates a unique event ID for meter events.
  Format: "event_" followed by a UUIDv7 with hyphens removed.

  ## Examples

      iex> MeterEvent.generate_event_id()
      "event_018e8b7c32d5b8a9c7d5e6f4a3c2b1a0"
  """
  def generate_event_id do
    "event_" <> String.replace(UUIDv7.generate(), "-", "")
  end
end
