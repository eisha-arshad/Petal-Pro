defmodule PetalPro.CountriesTest do
  use PetalPro.DataCase

  alias PetalPro.Countries

  describe "countries" do
    import PetalPro.CountriesFixtures

    alias PetalPro.Countries.Country

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
      member_of_eu: nil
    }

    test "list_countries/0 returns all countries" do
      country = country_fixture()
      assert Countries.list_countries() == [country]
    end

    test "get_country!/1 returns the country with given id" do
      country = country_fixture()
      assert Countries.get_country!(country.id) == country
    end

    test "create_country/1 with valid data creates a country" do
      valid_attrs = %{
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

      assert {:ok, %Country{} = country} = Countries.create_country(valid_attrs)
      assert country.name == "some name"
      assert country.alpha_2 == "some alpha_2"
      assert country.alpha_3 == "some alpha_3"
      assert country.country_code == 42
      assert country.iso_3166_2 == "some iso_3166_2"
      assert country.region == "some region"
      assert country.sub_region == "some sub_region"
      assert country.region_code == 42
      assert country.sub_region_code == 42
      assert country.intermediate_region_code == 42
      assert country.member_of_eu == true
    end

    test "create_country/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Countries.create_country(@invalid_attrs)
    end

    test "update_country/2 with valid data updates the country" do
      country = country_fixture()

      update_attrs = %{
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

      assert {:ok, %Country{} = country} = Countries.update_country(country, update_attrs)
      assert country.name == "some updated name"
      assert country.alpha_2 == "some updated alpha_2"
      assert country.alpha_3 == "some updated alpha_3"
      assert country.country_code == 43
      assert country.iso_3166_2 == "some updated iso_3166_2"
      assert country.region == "some updated region"
      assert country.sub_region == "some updated sub_region"
      assert country.region_code == 43
      assert country.sub_region_code == 43
      assert country.intermediate_region_code == 43
      assert country.member_of_eu == false
    end

    test "update_country/2 with invalid data returns error changeset" do
      country = country_fixture()
      assert {:error, %Ecto.Changeset{}} = Countries.update_country(country, @invalid_attrs)
      assert country == Countries.get_country!(country.id)
    end

    test "delete_country/1 deletes the country" do
      country = country_fixture()
      assert {:ok, %Country{}} = Countries.delete_country(country)
      assert_raise Ecto.NoResultsError, fn -> Countries.get_country!(country.id) end
    end

    test "change_country/1 returns a country changeset" do
      country = country_fixture()
      assert %Ecto.Changeset{} = Countries.change_country(country)
    end
  end
end
