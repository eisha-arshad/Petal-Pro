defmodule PetalProWeb.AuthLayout do
  @moduledoc false
  use Phoenix.Component
  use PetalComponents

  import PetalProWeb.BorderBeam

  attr :title, :string
  attr :home_page, :string, default: "/"
  slot(:inner_block)
  slot(:logo)
  slot(:top_links)
  slot(:bottom_links)

  def auth_layout(assigns) do
    ~H"""
    <div class="fixed h-full w-full overflow-y-scroll bg-gray-100 dark:bg-gray-900">
      <div class="flex flex-col justify-center py-12 sm:px-6 lg:px-8">
        <div class="text-center sm:mx-auto sm:w-full sm:max-w-md">
          <div class="mb-10 flex justify-center">
            <.link href={@home_page}>
              {render_slot(@logo)}
            </.link>
          </div>

          <.h2>
            {@title}
          </.h2>

          <%= if render_slot(@top_links) do %>
            <.p>
              {render_slot(@top_links)}
            </.p>
          <% end %>
        </div>
      </div>

      <div class="pb-20 sm:mx-auto sm:w-full sm:max-w-md">
        <.border_beam
          gradient_color_start="#34d80bff"
          gradient_color_end="#a31313ff"
          border_radius="0.75rem"
          animation_duration="10s"
          class="border-gray-200! bg-white px-4 py-8 dark:border-gray-700! dark:bg-gray-800 sm:rounded-lg sm:px-10"
        >
          {render_slot(@inner_block)}
        </.border_beam>

        <%= if render_slot(@bottom_links) do %>
          <div class="mt-5 text-center">
            {render_slot(@bottom_links)}
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
