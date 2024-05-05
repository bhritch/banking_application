defmodule BankingApp.Accounts.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias BankingApp.Accounts.Account

  schema "account_transactions" do
    field :account, :string
    field :time, :string
    field :amount, :decimal
    field :company, :string
    field :routing_number, :string
    field :secret, :string

    belongs_to :accounts,
      Account,
      foreign_key: :account_id,
      references: :id,
      on_replace: :nilify

    timestamps(type: :utc_datetime)
  end

  @transaction_fields ~w(account time amount company routing_number secret)a

  @doc false
  def changeset(trxn, attrs) do
    trxn
    |> cast(attrs, @transaction_fields)
  end
end
