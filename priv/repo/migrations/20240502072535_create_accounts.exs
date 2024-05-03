defmodule BankingApp.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :client_secret, :string
      add :token, :string
      add :state, :string
      add :city, :string
      add :country, :string
      add :company, :string

      timestamps(type: :utc_datetime)
    end
  end
end
