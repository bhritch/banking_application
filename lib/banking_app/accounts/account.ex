defmodule BankingApp.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias BankingApp.Accounts.Transaction

  schema "accounts" do
    field :token, :string
    field :client_secret, :string
    field :account, :string
    field :state, :string
    field :city, :string
    field :country, :string
    field :company, :string
    field :routing_number, :string

    has_many :transaction,
      Transaction,
      foreign_key: :account_id, references: :id

    timestamps(type: :utc_datetime)
  end

  @account_fields ~w(account token client_secret state city country company routing_number)a

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, @account_fields)
  end
end
