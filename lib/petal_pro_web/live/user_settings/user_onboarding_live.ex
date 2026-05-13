defmodule PetalProWeb.UserOnboardingLive do
  @moduledoc false
  use PetalProWeb, :live_view

  alias PetalPro.Accounts

  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(user_return_to: Map.get(params, "user_return_to", nil))
      |> assign_form(Accounts.change_profile(socket.assigns.current_user))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 z-10 overflow-y-auto">
      <div class="flex min-h-screen items-end justify-center px-4 pt-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 -z-10 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75 dark:bg-gray-800" />
        </div>

        <span class="hidden sm:inline-block sm:h-screen sm:align-middle" aria-hidden="true">
          &#8203;
        </span>
        <div
          class="inline-block transform overflow-hidden rounded-lg bg-white px-4 pt-5 pb-4 text-left align-bottom shadow-xl transition-all dark:bg-gray-900 sm:my-8 sm:w-full sm:max-w-lg sm:p-6 sm:align-middle"
          role="dialog"
          aria-modal="true"
          aria-labelledby="modal-headline"
        >
          <div>
            <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-green-100 text-2xl dark:bg-green-800">
              👋
            </div>
            <div class="mt-3 text-center sm:mt-5">
              <h3
                class="text-xl font-medium leading-6 text-gray-900 dark:text-white"
                id="modal-headline"
              >
                {gettext("Welcome!")}
              </h3>
              <div class="prose-sm mt-2 text-base text-gray-500 dark:text-gray-400">
                <p>
                  {gettext("To join our community, help us improve by completing your profile.")}
                </p>
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-6">
            <.form id="update_profile_form" for={@form} phx-submit="submit">
              <.field
                field={@form[:name]}
                label={gettext("What is your name?*")}
                placeholder={gettext("eg. John")}
                {alpine_autofocus()}
              />

              <.field
                type="checkbox"
                field={@form[:is_subscribed_to_marketing_notifications]}
                label={gettext("Allow marketing notifications")}
              />

              <div class="flex items-center justify-between">
                <.link class="text-sm underline" href={~p"/auth/sign-out"} method="delete">
                  {gettext("Sign out")}
                </.link>
                <.button>{gettext("Submit")}</.button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("submit", %{"user" => user_params}, socket) do
    user_params = Map.put(user_params, "is_onboarded", true)
    current_user = socket.assigns.current_user

    case Accounts.update_profile(current_user, user_params) do
      {:ok, updated_user} ->
        Accounts.user_lifecycle_action("after_update_profile", updated_user)

        socket =
          socket
          |> put_flash(:info, gettext("Thank you!"))
          |> push_navigate(to: socket.assigns.user_return_to || home_path(updated_user))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
