import Config

if config_env() == :prod do
  # Render provides PORT automatically
  port = String.to_integer(System.get_env("PORT") || "4000")

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      Example:
      ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 =
    if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :fixit, Fixit.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      Generate one with:
      mix phx.gen.secret
      """

  host =
    System.get_env("PHX_HOST") ||
      System.get_env("RENDER_EXTERNAL_HOSTNAME") ||
      "example.com"

  config :fixit, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :fixit, FixitWeb.Endpoint,
    # IMPORTANT
    server: true,
    url: [host: host, port: 443, scheme: "https"],
    check_origin: ["https://#{host}", "//#{host}"],
    http: [
      # bind to all interfaces
      ip: {0, 0, 0, 0},
      # use Render PORT
      port: port
    ],
    secret_key_base: secret_key_base

  resend_api_key =
    System.get_env("RESEND_API_KEY") ||
      System.get_env("RESEND_KEY") ||
      raise("RESEND_API_KEY (or RESEND_KEY) is missing.")

  mail_from_email =
    System.get_env("MAIL_FROM_EMAIL") ||
      System.get_env("SENDER_EMAIL") ||
      raise("MAIL_FROM_EMAIL (or SENDER_EMAIL) is missing.")

  config :fixit, Fixit.Mailer,
    adapter: Swoosh.Adapters.Resend,
    api_key: resend_api_key,
    from_name: System.get_env("MAIL_FROM_NAME") || "Fixit",
    from_email: mail_from_email
end
