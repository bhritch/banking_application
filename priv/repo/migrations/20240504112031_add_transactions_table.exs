defmodule BankingApp.Repo.Migrations.AddTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:account_transactions) do

      add :account_id, references(:accounts)
      add :account, :string
      add :time, :string
      add :amount, :decimal
      add :company, :string

      timestamps(type: :utc_datetime)
    end
  end
end
