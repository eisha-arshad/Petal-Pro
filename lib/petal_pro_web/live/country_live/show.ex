defmodule PetalProWeb.CountryLive.Show do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.PageComponents

  alias PetalPro.Countries

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:country, Countries.get_country!(id))}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/countries/#{socket.assigns.country}")}
  end

  defp page_title(:show), do: "Show Country"
  defp page_title(:edit), do: "Edit Country"
end
