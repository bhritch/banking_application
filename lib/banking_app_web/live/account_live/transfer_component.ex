defmodule BankingAppWeb.AccountLive.TransferComponent do
  require Logger
  use BankingAppWeb, :live_component

  alias BankingApp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Transfer all authorize transactions</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="transfer-form"
        phx-target={@myself}

        phx-submit="transfer"
      >
        <.input disabled field={@form[:account]} type="text" label="Account" />
        <:actions>
          <.button phx-disable-with="Transferring...">Transfer</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{account: account} = assigns, socket) do
    changeset = Accounts.change_account(account)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"account" => account_params}, socket) do
    changeset =
      socket.assigns.account
      |> Accounts.change_account(account_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("transfer", %{}, socket) do
    transfer_funds(socket, socket.assigns.action, %{})
  end

  defp transfer_funds(socket, :transfer, _account_params) do
    case Accounts.tranfer_funds(socket.assigns.account) do
      {:ok, account} ->
        notify_parent({:saved, account})

        {:noreply,
         socket
         |> put_flash(:info, "Funds successfully transfered.")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %{"error" => message}} ->
          {:noreply,
            socket
            |> put_flash(:error, message)
            |> push_patch(to: socket.assigns.patch)}
      {:error, message} ->
        {:noreply,
         socket
         |> put_flash(:error, message)
         |> push_patch(to: socket.assigns.patch)}

    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
