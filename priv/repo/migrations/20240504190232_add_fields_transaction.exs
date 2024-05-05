defmodule BankingApp.Repo.Migrations.AddFieldsTransaction do
  use Ecto.Migration

  def change do
    alter table(:account_transactions) do
      add :routing_number, :string
      add :secret, :string
    end
  end
end
