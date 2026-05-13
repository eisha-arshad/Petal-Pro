defmodule PetalPro.Billing.Providers.Stripe.Workers.MeterSyncWorker do
  @moduledoc """
  Worker for periodically syncing meter events to Stripe.
  """

  use Oban.Worker, queue: :billing

  alias PetalPro.Billing.Providers.Stripe.Services.SyncMeter

  require Logger

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("#{__MODULE__} running...")

    case SyncMeter.call() do
      :ok ->
        Logger.info("#{__MODULE__} completed successfully")
        :ok

      {:ok, result} ->
        Logger.info("#{__MODULE__} completed successfully with result: #{inspect(result)}")
        :ok

      {:error, operation, reason, changes} ->
        Logger.error(
          "#{__MODULE__} failed at operation #{inspect(operation)} with reason: #{inspect(reason)}, changes: #{inspect(changes)}"
        )

        {:error, reason}
    end
  end
end
