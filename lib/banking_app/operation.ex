defmodule BankingApp.Operation do
  @operation_url "#{System.get_env("API_BASE_URL")}/operations"

  def open_an_account(client_secret) do
    request_url = System.get_env("API_BASE_URL") <> "/accounts"

    payload =
      %{
        "client_secret" => String.trim(client_secret)
      }
      |> Jason.encode_to_iodata!()

    process_request(:post, request_url, headers(), payload)
    |> process_response()
  end

  def get_account_details(account) do
    payload =
      %{
        "type" => "GetAccount",
        "account" => account.account
      }
      |> Jason.encode_to_iodata!()

    headers = auth_headers(account.token)

    process_request(:post, @operation_url, headers, payload)
    |> IO.inspect()
    |> process_response()
  end

  def get_routing_details(account) do
    payload =
      %{
        "type" => "GetRouting",
        "state" => account.state
      }
      |> Jason.encode_to_iodata!()

    headers = auth_headers(account.token)

    process_request(:post, @operation_url, headers, payload)
    |> IO.inspect()
    |> process_response()
  end

  def list_transaction(_) do
    nil
  end

  def authorize_transfer(account, routing_number) do
    payload =
      %{
        "type" => "Authorize",
        "account" => account.account,
        "routing" => routing_number,
        "secret" => ""
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

  def process_response(response) do
    response
  end
end
