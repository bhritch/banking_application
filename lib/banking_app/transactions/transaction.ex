defmodule BankingApp.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias BankingApp.Accounts.Account

  schema "authorize_transactions" do
    field :token, :string
    field :amount, :decimal

    belongs_to :accounts,
      Account,
      foreign_key: :account_id,
      references: :id,
      on_replace: :nilify

    timestamps(type: :utc_datetime)
  end

  @transaction_fields ~w(token amount)a

  @doc false
  def changeset(trxn, attrs) do
    trxn
    |> cast(attrs, @transaction_fields)
  end
end
