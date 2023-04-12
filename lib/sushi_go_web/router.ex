defmodule SushiGoWeb.Router do
  use SushiGoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SushiGoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SushiGoWeb do
    pipe_through :browser

    live "/", LobbyLive
    get "/join", GameController, :join
    get "/leave", GameController, :leave
    get "/game/:invite", GameController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", SushiGoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:sushi_go, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SushiGoWeb.Telemetry
    end
  end
end
