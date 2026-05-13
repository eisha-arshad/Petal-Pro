defmodule PetalProWeb.BillingLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.OrgSettingsLayoutComponent
  import PetalProWeb.UserSettingsLayoutComponent

  alias PetalPro.Billing.Subscriptions
  alias PetalProWeb.BillingHelper

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:source, socket.assigns.live_action)
      |> assign(:cancelling, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, maybe_load_provider_data(socket)}
  end

  @impl true
  def handle_event("cancel_subscription", _attrs, socket) do
    send(self(), :cancel_subscription)

    {:noreply, assign(socket, :cancelling, true)}
  end

  @impl true
  def handle_info(:cancel_subscription, socket) do
    subscription = socket.assigns.subscription

    socket = assign(socket, :cancelling, false)

    case BillingHelper.cancel_subscription(subscription) do
      {:ok, subscription} ->
        customer = socket.assigns.customer
        current_user = socket.assigns.current_user
        current_org = socket.assigns.current_org

        Subscriptions.billing_lifecycle_action(
          "billing.cancel_subscription",
          current_user,
          current_org,
          %{
            subscription: subscription,
            customer: customer
          }
        )

        {:noreply, push_navigate(socket, to: billing_path(socket.assigns.source, socket.assigns))}

      {:error, reason} ->
        Logger.error("Error while cancelling subscription: #{inspect(reason)}")

        {:noreply,
         socket
         |> put_flash(:error, gettext("Something went wrong."))
         |> maybe_load_provider_data()}
    end
  end

  defp maybe_load_provider_data(socket) do
    subscription = socket.assigns[:subscription]

    assign_async(
      socket,
      [:subscription_async, :latest_invoice_async, :upcoming_invoice_async, :meter_summaries_async],
      fn ->
        provider_subscription = BillingHelper.fetch_subscription(subscription)
        latest_invoice = BillingHelper.fetch_latest_invoice(subscription)
        upcoming_invoice = BillingHelper.fetch_upcoming_invoice(subscription)

        meter_summaries = BillingHelper.get_meter_summaries(provider_subscription, upcoming_invoice)

        {:ok,
         %{
           subscription_async: provider_subscription,
           latest_invoice_async: latest_invoice,
           upcoming_invoice_async: upcoming_invoice,
           meter_summaries_async: meter_summaries
         }}
      end
    )
  end

  def billing_path(:user, _assigns), do: ~p"/app/billing"
  def billing_path(:org, assigns), do: ~p"/app/org/#{assigns.current_org.slug}/billing"

  defp subscribe_path(:user, _assigns), do: ~p"/app/subscribe"
  defp subscribe_path(:org, assigns), do: ~p"/app/org/#{assigns.current_org.slug}/subscribe"

  @impl true
  def render(assigns) do
    ~H"""
    <.billing_layout
      source={@source}
      current_user={@current_user}
      current_org={@current_org}
      current_membership={@current_membership}
      socket={@socket}
    >
      <.billing_details
        has_subscription={!is_nil(@subscription)}
        loading={@subscription_async.loading}
        failed={@subscription_async.failed}
        cancelling={@cancelling}
        subscription={if @subscription_async.ok?, do: @subscription_async.result}
        latest_invoice={if @latest_invoice_async.ok?, do: @latest_invoice_async.result}
        upcoming_invoice={if @upcoming_invoice_async.ok?, do: @upcoming_invoice_async.result}
        meter_summaries={if @meter_summaries_async.ok?, do: @meter_summaries_async.result}
        subscribe_path={subscribe_path(@source, assigns)}
      />
    </.billing_layout>
    """
  end

  attr :socket, :map, required: true
  attr :source, :atom, required: true
  attr :current_user, :map, default: nil
  attr :current_org, :map, default: nil
  attr :current_membership, :map, default: nil

  slot :inner_block

  defp billing_layout(%{source: :user} = assigns) do
    ~H"""
    <.settings_layout current_page={:billing} current_user={@current_user}>
      {render_slot(@inner_block)}
    </.settings_layout>
    """
  end

  defp billing_layout(%{source: :org} = assigns) do
    ~H"""
    <.org_settings_layout
      current_page={:org_billing}
      current_user={@current_user}
      current_org={@current_org}
      current_membership={@current_membership}
      socket={@socket}
    >
      {render_slot(@inner_block)}
    </.org_settings_layout>
    """
  end

  attr :has_subscription, :boolean
  attr :loading, :boolean
  attr :failed, :boolean
  attr :cancelling, :boolean, default: false
  attr :subscription, :map
  attr :latest_invoice, :map
  attr :upcoming_invoice, :map
  attr :meter_summaries, :list
  attr :subscribe_path, :string

  def billing_details(assigns) do
    ~H"""
    <div class="flex justify-between">
      <.h3>{gettext("Billing")}</.h3>

      <div class="flex items-center gap-2">
        <.button size="sm" link_type="live_redirect" to={@subscribe_path} color="light">
          <.icon name="hero-view-columns" class="h-4.5 w-4.5 mr-1" />
          {gettext("View plans")}
        </.button>

        <.spinner show={@cancelling} class="ml-1.5" />
        <.dropdown
          :if={@has_subscription && !@cancelling}
          class="ml-1.5 dark:shadow-lg"
          options_container_id="billing_options"
          menu_items_wrapper_class="dark:border dark:border-gray-600"
        >
          <.dropdown_menu_item
            disabled={!@subscription}
            phx-click="cancel_subscription"
            data-confirm={gettext("Are you sure?")}
            id="cancel-subscription"
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
            {gettext("Cancel Subscription")}
          </.dropdown_menu_item>
        </.dropdown>
      </div>
    </div>

    <.skeleton :if={@loading} />

    <div :if={@failed}>
      {gettext("Something went wrong with our payment provider. Please contact support.")}
    </div>

    <div :if={!@loading && !@subscription}>
      {gettext("No active subscriptions.")}
    </div>

    <.subscription
      :if={@subscription}
      subscription={@subscription}
      latest_invoice={@latest_invoice}
      upcoming_invoice={@upcoming_invoice}
    />

    <div :if={@meter_summaries && @meter_summaries != []} class="mt-5 grid gap-2">
      <.h4>{gettext("Usage")}</.h4>
      <.p>
        {gettext(
          "Please note that the following figures are an indication only. Actual amounts will be in the next invoice."
        )}
      </.p>
      <.meter_usage :for={meter_summary <- @meter_summaries} meter_summary={meter_summary} />
    </div>
    """
  end

  attr :subscription, :map, required: true
  attr :latest_invoice, :map
  attr :upcoming_invoice, :map

  defp subscription(assigns) do
    ~H"""
    <div>
      <span class="font-semibold">{gettext("Current plan:")}</span>
      {@subscription.product_name}
      <span :if={@subscription.trialing}>
        ({gettext("Trial")})
      </span>
    </div>
    <div>
      <.price
        price={@subscription.price}
        per_unit={@subscription.per_unit}
        currency={@subscription.currency}
        cycle={@subscription.cycle}
      />
    </div>

    <div class="mt-4">
      <span class="font-semibold">{gettext("Last invoice:")}</span>
      <span :if={@latest_invoice}>
        {Util.format_money(@latest_invoice.amount)}
        <span class="uppercase">{@latest_invoice.currency}</span>
      </span>
      <span :if={!@latest_invoice}>
        {gettext("-")}
      </span>
    </div>
    <div>
      <span class="font-semibold">{gettext("Upcoming:")}</span>
      <span :if={@upcoming_invoice}>
        {Util.format_money(@upcoming_invoice.amount)}
        <span class="uppercase">{@upcoming_invoice.currency}</span>
      </span>
      <span :if={!@upcoming_invoice}>
        {gettext("-")}
      </span>
    </div>
    <div>
      <span class="font-semibold">{gettext("Next charge:")}</span>
      {format_date(@subscription.next_charge_date)}
    </div>
    """
  end

  attr :meter_summary, :map, required: true

  defp meter_usage(assigns) do
    ~H"""
    <.h5>{@meter_summary.meter_name}</.h5>
    <.table rows={@meter_summary.usage}>
      <:col :let={usage} label={gettext("Date (UTC)")}>{format_date(usage.timestamp)}</:col>
      <:col :let={usage} label={gettext("Quantity")} class="text-end" row_class="text-end">
        {usage.quantity}
      </:col>
      <:col :let={usage} label={gettext("Amount")} class="text-end" row_class="text-end">
        {Util.format_money(usage.amount)}
      </:col>
    </.table>
    """
  end

  attr :price, :integer, required: true
  attr :per_unit, :integer, default: nil
  attr :currency, :string, required: true
  attr :cycle, :string, required: true

  defp price(%{per_unit: nil} = assigns) do
    ~H"""
    {Util.format_money(@price)}
    <span class="uppercase">{@currency}</span> / {@cycle}
    """
  end

  defp price(assigns) do
    ~H"""
    {Util.format_money(@price)} <span class="uppercase">{@currency}</span>
    per {@per_unit} {Inflex.inflect("unit", @per_unit)} / {@cycle}
    """
  end
end
