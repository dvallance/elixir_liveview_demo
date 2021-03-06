defmodule GamesWeb.Router do
  use GamesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {GamesWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GamesWeb do
    pipe_through :browser

    get "/", AuthenticationController, :login
    get "/authentication/login", AuthenticationController, :login
    post "/authentication/login", AuthenticationController, :log_in
    delete "/authentication/login", AuthenticationController, :log_out
  end

  scope "/demo", GamesWeb do
    pipe_through [:browser, GamesWeb.LoggedInPlug]
    get "/games", DemoController, :games
    # live "/games", GameLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", GamesWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: GamesWeb.Telemetry
    end
  end
end
