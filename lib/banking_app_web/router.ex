defmodule BankingAppWeb.Router do
  use BankingAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BankingAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BankingAppWeb do
    pipe_through :browser

    live "/", AccountLive.Index, :index

    live "/accounts", AccountLive.Index, :index
    live "/accounts/new", AccountLive.Index, :new
    live "/accounts/:id/edit", AccountLive.Index, :edit
    live "/accounts/:id/transfer", AccountLive.Index, :transfer


    live "/accounts/:id", AccountLive.Show, :show
    live "/accounts/:id/show/edit", AccountLive.Show, :edit
    live "/accounts/:id/authorize/:trxn_id", AccountLive.Show, :authorize
  end

  # Other scopes may use custom stacks.
  # scope "/api", BankingAppWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:banking_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BankingAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
