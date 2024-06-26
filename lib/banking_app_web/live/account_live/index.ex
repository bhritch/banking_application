defmodule BankingAppWeb.AccountLive.Index do
  use BankingAppWeb, :live_view

  alias BankingApp.Accounts
  alias BankingApp.Accounts.Account

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :accounts, Accounts.list_accounts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Account")
    |> assign(:account, Accounts.get_account!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Open new account")
    |> assign(:account, %Account{})
  end

  defp apply_action(socket, :transfer, %{"id" => id}) do
    socket
    |> assign(:page_title, "Transfer authorize transactions")
    |> assign(:account, Accounts.get_account(id))
    |> IO.inspect
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Accounts")
    |> assign(:account, nil)
  end

  @impl true
  def handle_info({BankingAppWeb.AccountLive.FormComponent, {:saved, account}}, socket) do
    {:noreply, stream_insert(socket, :accounts, account)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    account = Accounts.get_account!(id)
    {:ok, _} = Accounts.delete_account(account)

    {:noreply, stream_delete(socket, :accounts, account)}
  end
end
