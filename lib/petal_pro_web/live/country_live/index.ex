defmodule PetalProWeb.CountryLive.Index do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.PageComponents

  alias PetalPro.Countries
  alias PetalPro.Countries.Country

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :countries, Countries.list_countries())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Country")
    |> assign(:country, Countries.get_country!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Country")
    |> assign(:country, %Country{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Countries")
    |> assign(:country, nil)
  end

  @impl true
  def handle_info({PetalProWeb.CountryLive.FormComponent, {:saved, country}}, socket) do
    {:noreply, stream_insert(socket, :countries, country)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    country = Countries.get_country!(id)
    {:ok, _} = Countries.delete_country(country)

    socket = put_flash(socket, :info, "Country deleted")

    {:noreply, stream_delete(socket, :countries, country)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/countries")}
  end
end
