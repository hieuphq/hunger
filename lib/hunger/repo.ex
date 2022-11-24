defmodule Hunger.Repo do
  use Ecto.Repo,
    otp_app: :hunger,
    adapter: Ecto.Adapters.Postgres
end
