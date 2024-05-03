defmodule BankingApp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BankingApp.Accounts` context.
  """

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        client_secret: "some client_secret",
        token: "some token"
      })
      |> BankingApp.Accounts.create_account()

    account
  end
end
