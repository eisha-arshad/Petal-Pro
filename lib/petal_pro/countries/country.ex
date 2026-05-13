defmodule PetalPro.Countries.Country do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "countries" do
    field :name, :string
    field :alpha_2, :string
    field :alpha_3, :string
    field :country_code, :integer
    field :iso_3166_2, :string
    field :region, :string
    field :sub_region, :string
    field :region_code, :integer
    field :sub_region_code, :integer
    field :intermediate_region_code, :integer
    field :member_of_eu, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(country, attrs) do
    country
    |> cast(attrs, [
      :name,
      :alpha_2,
      :alpha_3,
      :country_code,
      :iso_3166_2,
      :region,
      :sub_region,
      :region_code,
      :sub_region_code,
      :intermediate_region_code,
      :member_of_eu
    ])
    |> validate_required([
      :name,
      :alpha_2,
      :alpha_3,
      :country_code,
      :iso_3166_2,
      :region,
      :sub_region,
      :region_code,
      :sub_region_code,
      :intermediate_region_code,
      :member_of_eu
    ])
  end
end
