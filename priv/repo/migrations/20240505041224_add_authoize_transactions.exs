defmodule BankingApp.Repo.Migrations.AddAuthoizeTransactions do
  use Ecto.Migration

  def change do
    create table(:authorize_transactions) do
      add :account_id, references(:accounts)
      add :token, :string
      add :amount, :decimal
      timestamps(type: :utc_datetime)
    end
  end
end
