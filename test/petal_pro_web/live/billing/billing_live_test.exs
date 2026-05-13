defmodule PetalProWeb.BillingLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.BillingFixtures
  import Phoenix.LiveViewTest

  alias PetalPro.Billing.Providers.Stripe.Provider
  alias PetalPro.Billing.Subscriptions

  setup :register_and_sign_in_user

  describe "user as source" do
    setup %{user: user} do
      Application.put_env(:petal_pro, :billing_entity, :user)

      customer = billing_customer_fixture(%{user_id: user.id})

      subscription_fixture(%{billing_customer_id: customer.id})

      [customer: customer]
    end

    test "shows current subscription", %{conn: conn} do
      vcr_name = "PetalProWeb.BillingLive user show"

      use_cassette vcr_name do
        assert {:ok, view, html} = live(conn, ~p"/app/billing")
        assert html =~ "Billing"
        assert html =~ "spinner"

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "$1.99"
        assert async_html =~ "Petal Pro Test Plan A"
        assert async_html =~ "month"
      end
    end

    test "cancels current subscription", %{conn: conn, customer: customer} do
      vcr_name = "PetalProWeb.BillingLive user cancel"

      use_cassette vcr_name do
        expect(Provider, :cancel_subscription, fn _ ->
          {:ok, stripe_subscription} = Provider.retrieve_subscription("sub_1RJX2hIWVkWpNCp7ztXBM8Cl")

          {:ok, Map.put(stripe_subscription, :status, "canceled")}
        end)

        assert Subscriptions.active_count(customer.id) == 1

        assert {:ok, view, _html} = live(conn, ~p"/app/billing")

        vcr_name
        |> async_timeout()
        |> Process.sleep()

        render_click(view, "cancel_subscription", %{})

        {:ok, view, _html} = live(conn, ~p"/app/billing")

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "No active subscription"
        assert Subscriptions.active_count(customer.id) == 0
      end
    end
  end

  describe "user as source without subscription" do
    setup %{user: user} do
      Application.put_env(:petal_pro, :billing_entity, :user)

      # Create customer without subscription
      customer = billing_customer_fixture(%{user_id: user.id})

      [customer: customer]
    end

    test "no active subscription", %{conn: conn} do
      vcr_name = "PetalProWeb.BillingLive user no subscription"

      use_cassette vcr_name do
        assert {:ok, view, html} = live(conn, ~p"/app/billing")
        assert html =~ "Billing"

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "No active subscription"
        refute view |> element("div.dropdown") |> has_element?()
      end
    end
  end

  describe "user as source with metered subscription" do
    setup %{user: user} do
      Application.put_env(:petal_pro, :billing_entity, :user)

      customer = billing_customer_fixture(%{user_id: user.id})

      subscription = metered_subscription_fixture(%{billing_customer_id: customer.id})

      [customer: customer, subscription: subscription]
    end

    test "shows metered subscription details", %{conn: conn, customer: customer, subscription: subscription} do
      vcr_name = "PetalProWeb.BillingLive user metered subscription"

      # Verify the subscription has metered items
      [subscription_item] = subscription.provider_subscription_items
      assert subscription_item[:metered] == true
      assert subscription_item[:unit_amount] == 500

      # Successfully synced events
      meter_event_fixture(%{
        billing_customer_id: customer.id,
        billing_subscription_id: subscription.id,
        meter_id: "mtr_123",
        quantity: 200,
        sent_at: DateTime.utc_now()
      })

      meter_event_fixture(%{
        billing_customer_id: customer.id,
        billing_subscription_id: subscription.id,
        meter_id: "mtr_123",
        quantity: 400,
        sent_at: DateTime.utc_now()
      })

      # Unsent event (should not appear in usage)
      meter_event_fixture(%{
        billing_customer_id: customer.id,
        billing_subscription_id: subscription.id,
        meter_id: "mtr_123",
        quantity: 1000
      })

      use_cassette vcr_name do
        assert {:ok, view, html} = live(conn, ~p"/app/billing")
        assert html =~ "Billing"
        assert html =~ "spinner"

        async_html = render_async(view, async_timeout(vcr_name))

        # Check balances (without third meter_event)
        assert async_html =~ "600"
        assert async_html =~ "$0.24"
      end
    end
  end

  describe "org as source" do
    setup %{org: org} do
      Application.put_env(:petal_pro, :billing_entity, :org)

      customer = billing_customer_fixture(%{org_id: org.id, source: :org})

      subscription_fixture(%{billing_customer_id: customer.id})

      [customer: customer]
    end

    test "shows current subscription", %{conn: conn, org: org} do
      vcr_name = "PetalProWeb.BillingLive org show"

      use_cassette vcr_name do
        assert {:ok, view, html} = live(conn, ~p"/app/org/#{org.slug}/billing")
        assert html =~ "Billing"
        assert html =~ "spinner"

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "$1.99"
        assert async_html =~ "Petal Pro Test Plan A"
        assert async_html =~ "month"
      end
    end

    test "cancels current subscription", %{conn: conn, org: org, customer: customer} do
      vcr_name = "PetalProWeb.BillingLive org cancel"

      use_cassette vcr_name do
        expect(Provider, :cancel_subscription, fn _ ->
          {:ok, stripe_subscription} = Provider.retrieve_subscription("sub_1RJX2hIWVkWpNCp7ztXBM8Cl")

          {:ok, Map.put(stripe_subscription, :status, "canceled")}
        end)

        assert Subscriptions.active_count(customer.id) == 1

        assert {:ok, view, _html} = live(conn, ~p"/app/org/#{org.slug}/billing")

        vcr_name
        |> async_timeout()
        |> Process.sleep()

        render_click(view, "cancel_subscription", %{})

        {:ok, view, _html} = live(conn, ~p"/app/org/#{org.slug}/billing")

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "No active subscription"
        assert Subscriptions.active_count(customer.id) == 0
      end
    end
  end

  describe "org as source without subscription" do
    setup %{org: org} do
      Application.put_env(:petal_pro, :billing_entity, :org)

      # Create customer without subscription
      customer = billing_customer_fixture(%{org_id: org.id, source: :org})

      [customer: customer]
    end

    test "no active subscription", %{conn: conn, org: org} do
      vcr_name = "PetalProWeb.BillingLive org no subscription"

      use_cassette vcr_name do
        assert {:ok, view, html} = live(conn, ~p"/app/org/#{org.slug}/billing")
        assert html =~ "Billing"

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "No active subscription"
        refute view |> element("div.dropdown") |> has_element?()
      end
    end
  end

  describe "org as source with metered subscription" do
    setup %{org: org} do
      Application.put_env(:petal_pro, :billing_entity, :org)

      # Create customer without subscription
      customer = billing_customer_fixture(%{org_id: org.id, source: :org})

      subscription = metered_subscription_fixture(%{billing_customer_id: customer.id})

      [customer: customer, subscription: subscription]
    end

    test "shows metered subscription details", %{conn: conn, org: org, customer: customer, subscription: subscription} do
      vcr_name = "PetalProWeb.BillingLive org metered subscription"

      # Verify the subscription has metered items
      [subscription_item] = subscription.provider_subscription_items
      assert subscription_item[:metered] == true
      assert subscription_item[:unit_amount] == 500

      # Successfully synced events
      meter_event_fixture(%{
        billing_customer_id: customer.id,
        billing_subscription_id: subscription.id,
        meter_id: "mtr_123",
        quantity: 200,
        sent_at: DateTime.utc_now()
      })

      meter_event_fixture(%{
        billing_customer_id: customer.id,
        billing_subscription_id: subscription.id,
        meter_id: "mtr_123",
        quantity: 400,
        sent_at: DateTime.utc_now()
      })

      # Unsent event (should not appear in usage)
      meter_event_fixture(%{
        billing_customer_id: customer.id,
        billing_subscription_id: subscription.id,
        meter_id: "mtr_123",
        quantity: 1000
      })

      use_cassette vcr_name do
        assert {:ok, view, html} = live(conn, ~p"/app/org/#{org.slug}/billing")
        assert html =~ "Billing"
        assert html =~ "spinner"

        async_html = render_async(view, async_timeout(vcr_name))

        # Check balances (without third meter_event)
        assert async_html =~ "600"
        assert async_html =~ "$0.24"
      end
    end
  end

  defp async_timeout(name) do
    if in_vcr?(name), do: 100, else: 2_500
  end
end
