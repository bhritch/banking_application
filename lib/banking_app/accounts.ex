defmodule BankingApp.Accounts do
  @moduledoc """
  The Accounts context.
  """

  require Logger

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias BankingApp.{
    Repo,
    Operation
  }

  alias BankingApp.Accounts.{
    Account,
    Transaction
  }

  alias BankingApp.Transactions.Transaction, as: Trxn
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

    case Operation.get_account_details(account, account.account) do
      {:ok, account_details} ->
        %{
          "account" => attrs
        } = account_details

        delete_trxn(account)
        delete_authorize_trxn(account)
        update_account(account, attrs)

      {:error, message} ->
        {:error, message}
    end
  end

  def fetch_trxn_account(account, account_number) do
    case Operation.get_account_details(account, account_number) do
      {:ok, account_details} ->
        %{
          "account" => attrs
        } = account_details

        {:ok, attrs}

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


  def update_trxn(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
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

  def delete_trxn(account) do
    from(t in Transaction, where: t.account_id == ^account.id) |> Repo.delete_all()
  end

  def delete_authorize_trxn(account) do
    from(t in Trxn, where: t.account_id == ^account.id) |> Repo.delete_all()
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

  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  def get_routing(account) do
    case Operation.get_routing_details(account, account.state) do
      {:ok, routing} ->
        update_account(account, routing)
      {:error, error} -> {:error, error}
    end
  end

  def update_trxn_routing(account, transaction, trxn_account) do
    %{
      "state" => state
    } = trxn_account

    case Operation.get_routing_details(account, state) do
      {:ok, routing} ->
        update_trxn(transaction, routing)
      {:error, error} -> {:error, error}
    end
  end

   def tranfer_funds(account) do
    with {:ok, params} <- get_authorize_transactions(account.id),
         {:ok, _} <- Operation.transfer_funds(account, params) do
      {:ok, account}
    else
      {:error, message} ->
        Logger.warning "1 #{inspect(message)}"
        {:error, message}
      {:error, %{"error" => message}} ->
        Logger.warning "2 #{inspect(message)}"
        {:error, message}
      err ->
        Logger.warning "#{inspect(err)}"
        {:error, "3 Something went wrong."}
    end
  end

  def get_transactions_by_id(id) do
    query =
      from t in Transaction,
      left_join: a in assoc(t, :accounts),
      where: t.id == ^id,
      preload: [accounts: a]
    Repo.one(query)
  end

  def get_transactions(id) do
    account_id = String.to_integer(id)

    query =
      from t in Transaction,
      where: t.account_id == ^account_id

    case Repo.all(query) do
      [] ->
        account = get_account!(account_id)
        case Operation.get_list_transaction(account) do
          {:ok, %{"transactions" => transactions}} ->
            multi = Multi.new()
            multi =
              transactions
                |> Enum.with_index()
                |> Enum.reduce(multi, fn {trxn, idx}, multi ->
                  trxn_params =
                    %Transaction{account_id: account_id}
                      |> Transaction.changeset(trxn)
                  Multi.insert(multi, {:insert_trxn, idx}, trxn_params)
                end)
            multi |> Repo.transaction

            get_transactions(id)

          {:error, %{"error" => message}} -> {:error, message}
        end
      txn ->
        txn
    end

  end

  def authorize(account, trxn_account,  %{"transaction" => %{"secret" => secret}}) do
    case Operation.authorize_transfer(account, trxn_account, secret) do
      {:ok, authorize} ->
        %{
          "checks" => checks,
          "error" => error
        } = authorize

        if is_nil(error) do
          %{
            "token" => token,
            "amount" => amount
          } = authorize

          payload = %{
            "token" => token,
            "amount" => amount
          }

          %Trxn{account_id: account.id}
            |> Trxn.changeset(payload)
            |> IO.inspect()
            |> Repo.insert()
        else
          error_message = Enum.map(checks, fn check ->
            "#{check["letter"]} is #{check["match"]}"
          end)
          |> Enum.join(", ")
          {:error, error_message}
        end

      {:error, %{"error" => error}} ->
        {:error, error}
    end
  end

  def get_authorize_transactions(account_id) do
    query =
      from t in Trxn,
      where: t.account_id == ^account_id

    case Repo.all(query) do
      [] ->
        {:error, "No authorize transactions found."}
      transactions ->
        tokens = Enum.map(transactions, fn trxn ->
          trxn.token
        end)
        total = Enum.reduce(transactions, 0, fn trxn, acc ->
          Decimal.to_float(trxn.amount) + acc
        end)
        {:ok, %{"tokens" => tokens, "total" => total}}
    end
  end

end
