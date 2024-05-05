defmodule BankingApp.Operation do

  @operation_url "#{System.get_env("API_BASE_URL")}/operations"
  @account_url "#{System.get_env("API_BASE_URL")}/accounts"

  require Logger

  def open_an_account(client_secret) do
    payload =
      %{
        "client_secret" => String.trim(client_secret)
      }
      |> Jason.encode_to_iodata!()

    process_request(:post, @account_url, headers(), payload)
    |> IO.inspect()
    |> process_response()
  end

  def get_account_details(account, account_number) do
    payload =
      %{
        "type" => "GetAccount",
        "account" => account_number
      }
      |> Jason.encode_to_iodata!()

    headers = auth_headers(account.token)

    process_request(:post, @operation_url, headers, payload)
    |> IO.inspect()
    |> process_response()
  end

  def get_list_transaction(account) do
    payload =
      %{
        "type" => "ListTransactions"
      }
      |> Jason.encode_to_iodata!()

    headers = auth_headers(account.token)

    process_request(:post, @operation_url, headers, payload)
    |> IO.inspect()
    |> process_response()
  end

  def get_routing_details(account, state) do
    payload =
      %{
        "type" => "GetRouting",
        "state" => state
      }
      |> Jason.encode_to_iodata!()

    headers = auth_headers(account.token)

    process_request(:post, @operation_url, headers, payload)
    |> IO.inspect()
    |> process_response()
  end

  def authorize_transfer(account, from_account, secret) do

    payload =
      %{
        "type" => "Authorize",
        "account" => from_account.account,
        "routing" => from_account.routing_number,
        "secret" => secret
      }
      |> Jason.encode_to_iodata!()

    headers = auth_headers(account.token)

    process_request(:post, @operation_url, headers, payload)
    |> IO.inspect()
    |> process_response()
  end

  def transfer_funds(account, params) do


    %{
      "tokens" => tokens,
      "total" => total
    } = params
    Logger.warning "#{inspect(params, pretty: true)}"
    payload =
      %{
        "type" => "Transfer",
        "authorizations" => tokens,
        "total" => total
      }
      |> Jason.encode_to_iodata!()


    headers = auth_headers(account.token)

    process_request(:post, @operation_url, headers, payload)
    |> IO.inspect()
    |> process_response()

  end

  def headers() do
    [
      {"Accept", "application/json"},
      {"Content-Type", "application/json"}
    ]
  end

  def auth_headers(token) do
    headers() ++
      [
        {"Authorization", "Bearer #{token}"}
      ]
  end

  def process_request(method, url, headers, body) do
    Finch.build(
      method,
      url,
      headers,
      body
    )
    |> Finch.request(BankingApp.Finch)
  end

  def process_response({:ok, response}) do
    %Finch.Response{body: body} = response

    case response do
      %Finch.Response{status: 200} ->
        {:ok, Jason.decode!(body)}
      _ ->
        {:error, Jason.decode!(body)}
    end
  end

  def process_response({:error, %Mint.TransportError{reason: :timeout}}) do
    {:error, %{"error" => "Something went wrong. timeout"}}
  end

  def process_response(_) do
    {:error, %{"error" => "Something went wrong."}}
  end

end
