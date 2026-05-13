defmodule PetalPro.CountriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PetalPro.Countries` context.
  """

  @doc """
  Generate a country.
  """
  def country_fixture(attrs \\ %{}) do
    {:ok, country} =
      attrs
      |> Enum.into(%{
        alpha_2: "some alpha_2",
        alpha_3: "some alpha_3",
        country_code: 42,
        intermediate_region_code: 42,
        iso_3166_2: "some iso_3166_2",
        iso_3166_2: "some iso_3166_2",
        member_of_eu: true,
        name: "some name",
        region: "some region",
        region_code: 42,
        sub_region: "some sub_region",
        sub_region_code: 42
      })
      |> PetalPro.Countries.create_country()

    country
  end
end
