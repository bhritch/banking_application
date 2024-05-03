defmodule BankingApp.Accounts do
  @moduledoc """
  The Accounts context.
  """

  require Logger

  import Ecto.Query, warn: false

  alias BankingApp.{
    Repo,
    Operation
  }

  alias BankingApp.Accounts.Account

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %{
      "client_secret" => client_secret
    } = attrs

    case Operation.open_an_account(client_secret) do
      {:ok, account} ->
        attrs =
          Map.merge(attrs, %{
            "token" => account["access_token"],
            "account" => account["account"]
          })

        insert_account(client_secret, attrs)

      {:error, message} ->
        {:error, message}
    end
  end

  def insert_account(client_secret, attrs) do
    case Repo.get_by(Account, client_secret: client_secret) do
      nil -> %Account{}
      account -> account
    end
    |> Account.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def fetch_account(%Account{} = account) do
    # %{"account" => attrs} = Operation.get_account_details(account)

    case Operation.get_account_details(account) do
      {:ok, account_details} ->
        %{
          "account" => attrs
        } = account_details

        update_account(account, attrs)

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end
end
