defmodule BankingApp.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :token, :string
    field :client_secret, :string
    field :account, :string
    field :state, :string
    field :city, :string
    field :country, :string
    field :company, :string

    timestamps(type: :utc_datetime)
  end

  @account_fields ~w(account token client_secret state city country company)a

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, @account_fields)
  end
end
