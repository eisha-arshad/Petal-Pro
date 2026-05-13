defmodule PetalPro.Orgs.Org do
  @moduledoc false
  use PetalPro.Schema

  alias PetalPro.Accounts.User
  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Extensions.Ecto.ChangesetExt
  alias PetalPro.Orgs.Invitation
  alias PetalPro.Orgs.Membership

  @derive {Phoenix.Param, key: :slug}
  typed_schema "orgs" do
    field :name, :string
    field :slug, :string

    has_many :memberships, Membership
    has_many :invitations, Invitation
    many_to_many :users, User, join_through: "orgs_memberships", unique: true
    has_one :customer, Customer

    timestamps()
  end

  def insert_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name])
    |> validate_name()
    |> name_to_slug()
    |> unique_constraint(:slug)
    |> unsafe_validate_unique(:slug, PetalPro.Repo)
  end

  def validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 160)
  end

  def update_changeset(org, attrs) do
    org
    |> cast(attrs, [:name])
    |> validate_name()
  end

  defp name_to_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      new_name ->
        change(changeset, %{slug: Slug.slugify(new_name)})
    end
  end
end
