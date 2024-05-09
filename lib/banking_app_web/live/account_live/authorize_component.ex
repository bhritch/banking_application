defmodule BankingAppWeb.AccountLive.AuthorizeComponent do
  require Logger
  use BankingAppWeb, :live_component

  alias BankingApp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle >
          Guess the secret in 3 tries.
        </:subtitle>

        <:subtitle :if={@error}>
          <div role="alert" class="mt-5">
          <div class="bg-red-500 text-white font-bold rounded-t px-4 py-2">
          </div>
          <div class="border border-t-0 border-red-400 rounded-b bg-red-100 px-4 py-3 text-red-700">
            <p><%= @error %></p>
          </div>
        </div>
        </:subtitle>
      </.header>


      <.simple_form
        for={@form}
        id="authorize-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="authorize"
      >
        <.input disabled field={@form[:account]} type="text" label="Account" />
        <.input field={@form[:secret]} type="text" label="Secret" />
        <:actions>
          <.button phx-disable-with="Authenticating...">Authorize</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{transaction: transaction} = assigns, socket) do
    changeset = Accounts.change_transaction(transaction)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign_error(nil)}
  end

  @impl true
  def handle_event("validate", %{"transaction" => transaction_params}, socket) do
    changeset =
      socket.assigns.transaction
      |> Accounts.change_transaction(transaction_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("authorize", params, socket) do

    trxn = socket.assigns.transaction

    if is_nil(trxn.routing_number) do

      with {:ok, trxn_account} <- Accounts.fetch_trxn_account(trxn.accounts, trxn.account),
      {:ok, updated_trxn} <- Accounts.update_trxn_routing(trxn.accounts, trxn, trxn_account) do
        assign(socket, :transaction, updated_trxn)
        apply_authorization(socket, trxn.accounts, updated_trxn, params)
      else

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
    else

      apply_authorization(socket, trxn.accounts, trxn, params)
    end

  end

  def apply_authorization(socket, account, trxn, params) do
    case Accounts.authorize(account, trxn, params) do
      {:ok, authorize} ->
        notify_parent({:authorized, authorize})
        {:noreply,
          socket
          |> put_flash(:info, "Authorized and ready for transfer.")
          |> push_patch(to: socket.assigns.patch)}

      {:error, message} ->

        {:noreply, assign_error(socket, message)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_error(socket, error_message) do
    assign(socket, :error, error_message)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
