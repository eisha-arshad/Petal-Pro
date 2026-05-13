defmodule PetalProWeb.BillingComponents do
  @moduledoc false
  use Phoenix.Component
  use PetalProWeb, :verified_routes
  use PetalComponents
  use Gettext, backend: PetalProWeb.Gettext

  attr :panels, :integer, default: 3
  attr :interval_selector, :boolean, default: false
  attr :rest, :global
  slot :default

  def pricing_panels_container(assigns) do
    ~H"""
    <div x-data="{ interval: 'month' }">
      <div :if={@interval_selector} class="flex justify-center">
        <div class="grid grid-cols-2 gap-x-1 rounded-full bg-gray-100 p-1 text-center text-xs font-semibold leading-5 text-black dark:bg-white/20 dark:text-white">
          <label
            class="cursor-pointer rounded-full px-4 py-2"
            @click="interval = 'month'"
            x-bind:class="{ 'bg-primary-500 text-white': interval == 'month' }"
          >
            <input type="radio" name="frequency" value="monthly" class="sr-only" />
            <span>Monthly</span>
          </label>
          <label
            class="cursor-pointer rounded-full px-4 py-2"
            @click="interval = 'year'"
            x-bind:class="{ 'bg-primary-500 text-white': interval == 'year' }"
          >
            <input type="radio" name="frequency" value="annually" class="sr-only" />
            <span>Annually</span>
          </label>
        </div>
      </div>

      <div
        {@rest}
        class={[
          "isolate mx-auto mt-10 grid max-w-md grid-cols-1 gap-8 lg:mx-0 lg:max-w-none",
          pricing_panels_container_css(@panels)
        ]}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil, doc: "Outer div class"
  attr :label, :string
  attr :description, :string
  attr :features, :list, default: []
  attr :most_popular, :boolean, default: false
  attr :rest, :global
  attr :is_current_plan, :boolean, default: false

  slot :default

  def pricing_panel(assigns) do
    ~H"""
    <div class={"#{if @most_popular || @is_current_plan, do: ring_style(true), else: ring_style(false)} #{@class} rounded-3xl p-8 shadow-xl xl:p-10"}>
      <div style="background: linear-gradient(270deg, rgba(153, 238, 255, 0) 0%, rgb(255, 255, 255) 49.5495%, rgba(255, 255, 255, 0) 100%); flex: 0 0 auto; height: 1px; left: calc(14.8579%); opacity: 0.5; overflow: hidden; position: absolute; top: 0px; user-select: none; width: 70%; z-index: 1; margin-top: -1px;">
      </div>
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold leading-8 text-black dark:text-white">
          {@label}
        </h3>
        <%= if @most_popular || @is_current_plan do %>
          <div class="bg-primary-50 border-primary-600 text-primary-700 inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-normal transition-colors hover:bg-primary/80 focus:ring-ring focus:outline-hidden focus:ring-2 focus:ring-offset-2 dark:bg-primary-800/30 dark:border-primary-400 dark:text-primary-400">
            <%= if @most_popular do %>
              {gettext("Most Popular ✨")}
            <% else %>
              {gettext("Current Plan")}
            <% end %>
          </div>
        <% end %>
      </div>
      <p class="mt-4 text-sm leading-6 text-gray-700 dark:text-gray-300">
        {@description}
      </p>
      {render_slot(@inner_block)}
      <ul class="mt-8 space-y-3 text-sm leading-6 text-gray-700 dark:text-gray-300 xl:mt-10">
        <%= for feature <- @features do %>
          <li class="flex gap-x-3">
            <svg
              class="h-6 w-5 flex-none text-black dark:text-white"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                clip-rule="evenodd"
              />
            </svg>
            <span>{feature}</span>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  defp ring_style(true) do
    "ring-2 bg-gray-400/5 dark:shadow-none ring-primary-400 dark:ring-primary-400 shadow-gray-400/5"
  end

  defp ring_style(false) do
    "ring-1 bg-gray-400/5 dark:shadow-none ring-gray-950/5 dark:ring-gray-200/20 shadow-gray-400/5"
  end

  attr :id, :string
  attr :interval, :atom
  attr :amount, :integer, default: nil
  attr :unit_amount, :integer, default: nil
  attr :per_units, :integer, default: nil
  attr :button_label, :string, default: "Subscribe"
  attr :button_props, :map, default: %{}
  attr :is_public, :boolean, default: false
  attr :is_current_plan, :boolean, default: false
  attr :billing_path, :string, default: "/app/billing"

  def item_price(assigns) do
    ~H"""
    <div id={@id} x-bind:class={"{ 'hidden': interval != '#{@interval}' }"}>
      <p :if={@amount} class="mt-6 flex items-baseline gap-x-1">
        <span class="text-4xl font-bold tracking-tight text-black dark:text-white">
          <%= case @interval do %>
            <% :month -> %>
              {Util.format_money(@amount)}
            <% :year -> %>
              {Util.format_money(div(@amount, 12))}
          <% end %>
        </span>
        <span class="text-sm font-semibold leading-6 text-gray-700 dark:text-gray-300">
          /
          <%= case @interval do %>
            <% :month -> %>
              {gettext("month")}
            <% :year -> %>
              {gettext("month (paid yearly)")}
          <% end %>
        </span>
      </p>

      <p :if={@unit_amount} class="mt-2 text-xl tracking-tight text-black dark:text-white">
        {Util.format_money(@unit_amount)} {gettext("per")} {@per_units} {gettext("units")} / {@interval}
      </p>

      <%= if @is_public do %>
        <.button
          color="light"
          class="mt-6 w-full rounded-md border-none bg-gray-200 px-3 py-2 text-center text-sm font-semibold leading-6 text-black hover:bg-gray-300 dark:bg-white/20 dark:text-white dark:hover:bg-white/30"
          label={@button_label}
          link_type="live_redirect"
          to={~p"/auth/register"}
        />
      <% else %>
        <%= if @is_current_plan do %>
          <.button
            to={@billing_path}
            link_type="live_redirect"
            label={@button_label}
            class="mt-6 w-full"
            {@button_props}
          />
        <% else %>
          <.button label={@button_label} class="mt-6 w-full" {@button_props} />
        <% end %>
      <% end %>
    </div>
    """
  end

  defp pricing_panels_container_css(1), do: ""
  defp pricing_panels_container_css(n), do: "lg:grid-cols-#{n}"
end
