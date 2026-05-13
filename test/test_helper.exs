Mimic.copy(PetalPro.Notifications.UserMailer)
Mimic.copy(PetalPro.Billing.Providers.Stripe.Provider)
Mimic.copy(PetalPro.Billing.Providers.Stripe.Services.SyncSubscription)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PetalPro.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, PetalProWeb.Endpoint.url())

"screenshots/*"
|> Path.wildcard()
|> Enum.each(&File.rm/1)
