defmodule BankingApp.Repo.Migrations.AddRountingNumber do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :routing_number, :string
    end
  end
end
