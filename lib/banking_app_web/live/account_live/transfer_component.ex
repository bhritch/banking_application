defmodule BankingAppWeb.AccountLive.TransferComponent do
  use BankingAppWeb, :live_component

  alias BankingApp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage account records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="transfer-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:client_secret]} type="text" label="Client secret" />
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

  def handle_event("save", %{"account" => account_params}, socket) do
    save_account(socket, socket.assigns.action, account_params)
  end

  defp save_account(socket, :edit, account_params) do
    case Accounts.update_account(socket.assigns.account, account_params) do
      {:ok, account} ->
        notify_parent({:saved, account})

        {:noreply,
         socket
         |> put_flash(:info, "Account updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_account(socket, :new, account_params) do
    with {:ok, account} <- Accounts.create_account(account_params),
         {:ok, updated_account} <- Accounts.fetch_account(account) do
      notify_parent({:saved, updated_account})

      {:noreply,
       socket
       |> put_flash(:info, "Account created successfully")
       |> push_patch(to: socket.assigns.patch)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, message} ->
        socket
        |> put_flash(:danger, message)
        |> push_patch(to: socket.assigns.patch)

      _ ->
        socket
        |> put_flash(:danger, "Something went wrong.")
        |> push_patch(to: socket.assigns.patch)
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
