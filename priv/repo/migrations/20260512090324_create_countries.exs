defmodule PetalPro.Repo.Migrations.CreateCountries do
  use Ecto.Migration

  def change do
    create table(:countries) do
      add :name, :string
      add :alpha_2, :string
      add :alpha_3, :string
      add :country_code, :integer
      add :iso_3166_2, :string
      add :region, :string
      add :sub_region, :string
      add :region_code, :integer
      add :sub_region_code, :integer
      add :intermediate_region_code, :integer
      add :member_of_eu, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
