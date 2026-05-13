defmodule PetalPro.Billing.Meters.CollectMeterEvents do
  @moduledoc """
  GenServer for asynchronously collecting meter events.
  Provides a non-blocking mechanism for capturing meter events and writing them to the database.
  """
  use GenServer

  alias PetalPro.Billing.Meters.MeterEvent
  alias PetalPro.Repo

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Enqueues a usage event to be recorded in the database.
  This is the main public interface for recording usage events.
  """
  def enqueue_meter_event(meter_id, billing_customer_id, subscription_id, quantity \\ 1, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:meter_event, meter_id, billing_customer_id, subscription_id, quantity, metadata})
  end

  @impl true
  def init(_opts) do
    # Start a Task.Supervisor for managing our async operations
    {:ok, supervisor} = Task.Supervisor.start_link(name: :"#{__MODULE__}.TaskSupervisor")
    {:ok, %{supervisor: supervisor}}
  end

  @impl true
  def handle_cast(
        {:meter_event, meter_id, billing_customer_id, subscription_id, quantity, metadata},
        %{supervisor: supervisor} = state
      ) do
    # Start the task under supervision and use Repo.put_dynamic_repo to ensure proper connection handling
    case Task.Supervisor.start_child(supervisor, fn ->
           # Ensure we're using the correct repo for the current process
           repo = Repo.get_dynamic_repo()
           Repo.put_dynamic_repo(repo)

           event_id = MeterEvent.generate_event_id()

           case %MeterEvent{}
                |> MeterEvent.changeset(%{
                  meter_id: meter_id,
                  event_id: event_id,
                  billing_customer_id: billing_customer_id,
                  billing_subscription_id: subscription_id,
                  quantity: quantity,
                  metadata: metadata
                })
                |> Repo.insert() do
             {:ok, meter_event} ->
               Logger.debug("Successfully inserted meter event #{meter_event.id} for meter #{meter_id}")

             {:error, changeset} ->
               Logger.error("Failed to insert meter event for meter #{meter_id}: #{inspect(changeset.errors)}")
           end
         end) do
      {:ok, _pid} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to start task for meter event collection: #{inspect(reason)}")
    end

    {:noreply, state}
  end
end
