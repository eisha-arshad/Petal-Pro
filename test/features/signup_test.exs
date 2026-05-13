defmodule PetalPro.Features.SignupTest do
  use ExUnit.Case
  use Wallaby.Feature
  use PetalProWeb, :verified_routes

  import PetalPro.AccountsFixtures
  import Wallaby.Query

  alias Wallaby.Query

  feature "users can create an account", %{session: session} do
    session =
      session
      |> visit(~p"/auth/register")
      |> assert_has(Query.text("Register"))
      |> fill_in(text_field("user[name]"), with: "Bob")
      |> fill_in(text_field("user[email]"), with: "bob@example.com")
      |> fill_in(text_field("user[password]"), with: "password")
      |> click(button("Create account"))
      |> assert_has(Query.text("Please confirm your email"))

    assert current_path(session) =~ "/auth/confirm"
  end

  feature "users get onboarded if user.is_onboarded is false", %{session: session} do
    user = confirmed_user_fixture(%{is_onboarded: false})

    session =
      session
      |> visit(~p"/auth/sign-in")
      |> fill_in(text_field("user[email]"), with: user.email)
      |> fill_in(text_field("user[password]"), with: "password")
      |> click(button("Sign in"))
      |> assert_has(Query.text("Welcome!"))
      |> fill_in(text_field("user[name]"), with: "Jerry")
      |> click(button("Submit"))
      |> assert_has(Query.text("Welcome, Jerry"))

    assert current_path(session) =~ "/app"
  end

  feature "users don't get onboarded if user.is_onboarded is true", %{session: session} do
    user = confirmed_user_fixture(%{is_onboarded: true})

    session =
      session
      |> visit(~p"/auth/sign-in")
      |> fill_in(text_field("user[email]"), with: user.email)
      |> fill_in(text_field("user[password]"), with: "password")
      |> click(button("Sign in"))

    assert current_path(session) =~ "/app"
  end
end
