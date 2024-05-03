defmodule BankingApp.Repo.Migrations.AddAccountColumn do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :account, :string
    end
  end
end
