defmodule PetalPro.Repo.Migrations.CreateBillingMeterEvents do
  use Ecto.Migration

  def change do
    create table(:billing_meter_events) do
      add :meter_id, :string, null: false
      add :event_id, :string, null: false
      add :quantity, :integer, null: false, default: 1
      add :metadata, :map
      add :sent_at, :utc_datetime
      add :error_message, :text

      add :billing_customer_id, references(:billing_customers, on_delete: :delete_all),
        null: false

      add :billing_subscription_id, references(:billing_subscriptions, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:billing_meter_events, [:meter_id])
    create index(:billing_meter_events, [:sent_at])
    create index(:billing_meter_events, [:billing_customer_id])
    create index(:billing_meter_events, [:billing_subscription_id])
    create index(:billing_meter_events, [:inserted_at])
  end
end
