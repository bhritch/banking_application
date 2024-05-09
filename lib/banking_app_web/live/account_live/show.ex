defmodule BankingAppWeb.AccountLive.Show do
  use BankingAppWeb, :live_view

  alias BankingApp.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

   @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Show Account")
    |> assign(:account, Accounts.get_account!(id))
    |> assign(:transactions, Accounts.get_transactions(id))
  end

  defp apply_action(socket, :authorize, %{"id" => id, "trxn_id" => trxn_id}) do
    socket
    |> assign(:page_title, "Authorize funds to be transferred out of this account")
    |> assign(:account, Accounts.get_account!(id))
    |> assign(:transactions, Accounts.get_transactions(id))
    |> assign(:transaction, Accounts.get_transactions_by_id(trxn_id))

  end

end
