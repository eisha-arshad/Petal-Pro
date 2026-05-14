defmodule PetalProWeb.CountryLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.CountriesFixtures
  import Phoenix.LiveViewTest

  @create_attrs %{
    name: "some name",
    alpha_2: "some alpha_2",
    alpha_3: "some alpha_3",
    country_code: 42,
    iso_3166_2: "some iso_3166_2",
    region: "some region",
    sub_region: "some sub_region",
    region_code: 42,
    sub_region_code: 42,
    intermediate_region_code: 42,
    member_of_eu: true
  }
  @update_attrs %{
    name: "some updated name",
    alpha_2: "some updated alpha_2",
    alpha_3: "some updated alpha_3",
    country_code: 43,
    iso_3166_2: "some updated iso_3166_2",
    region: "some updated region",
    sub_region: "some updated sub_region",
    region_code: 43,
    sub_region_code: 43,
    intermediate_region_code: 43,
    member_of_eu: false
  }
  @invalid_attrs %{
    name: nil,
    alpha_2: nil,
    alpha_3: nil,
    country_code: nil,
    iso_3166_2: nil,
    region: nil,
    sub_region: nil,
    region_code: nil,
    sub_region_code: nil,
    intermediate_region_code: nil,
    member_of_eu: false
  }

  defp create_country(_) do
    country = country_fixture()
    %{country: country}
  end

  describe "Index" do
    setup [:create_country]

    test "lists all countries", %{conn: conn, country: country} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/countries")

      assert html =~ "Listing Countries"
      assert html =~ country.name
    end

    test "saves new country", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/countries")

      assert index_live |> element("a", "New Country") |> render_click() =~
               "New Country"

      assert_patch(index_live, ~p"/countries/new")

      assert index_live
             |> form("#country-form", country: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#country-form", country: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/countries")

      html = render(index_live)
      assert html =~ "Country created successfully"
      assert html =~ "some name"
    end

    test "updates country in listing", %{conn: conn, country: country} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/countries")

      assert index_live |> element("a[href='/countries/#{country.id}/edit']", "Edit") |> render_click() =~
               "Edit Country"

      assert_patch(index_live, ~p"/countries/#{country}/edit")

      assert index_live
             |> form("#country-form", country: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#country-form", country: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/countries")

      html = render(index_live)
      assert html =~ "Country updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes country in listing", %{conn: conn, country: country} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/countries")

      assert index_live |> element("#countries-#{country.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "a[phx-value-id=#{country.id}]")
    end
  end

  describe "Show" do
    setup [:create_country]

    test "displays country", %{conn: conn, country: country} do
      {:ok, _show_live, html} = live(conn, ~p"/countries/#{country}")

      assert html =~ "Show Country"
      assert html =~ country.name
    end

    test "updates country within modal", %{conn: conn, country: country} do
      {:ok, show_live, _html} = live(conn, ~p"/countries/#{country}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Country"

      assert_patch(show_live, ~p"/countries/#{country}/show/edit")

      assert show_live
             |> form("#country-form", country: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#country-form", country: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/countries/#{country}")

      html = render(show_live)
      assert html =~ "Country updated successfully"
      assert html =~ "some updated name"
    end
  end
end
