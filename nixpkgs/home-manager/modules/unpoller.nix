{ config, pkgs, ... }:

/*
  Unpoller (UniFi Poller) helper for Darwin Home Manager.

  What this does:
  - Installs `prometheus` and `grafana` into the user profile.
  - Provides `unpoller`, a manual CLI wrapper that:
    - pulls the UniFi API token from 1Password via `op-secret-cache`
    - writes a temporary config file (TOML) under:
      ~/Library/Application Support/unpoller
    - starts Prometheus locally (default) for storage + scraping
    - starts Grafana locally (default) with embedded Unpoller dashboards
    - runs unpoller and logs to the current directory (or --log-dir)

  Usage:
    unpoller --op-path 'op://Vault/Item/Field'
    UNPOLLER_OP_PATH='op://Vault/Item/Field' unpoller
    unpoller --op-path 'op://Vault/Item/Field' --log-dir ~/metrics
    unpoller --no-prometheus --op-path 'op://Vault/Item/Field'
    unpoller --no-grafana --op-path 'op://Vault/Item/Field'
    unpoller --raw -- --help

  Notes:
  - No secrets are stored in the Nix store. The op path is supplied at runtime.
  - The config is removed on exit; logs and local data remain in the chosen directory.
  - Unpoller does not backfill historical data; it only exports current state on
    each poll. History is provided by your TSDB retention (e.g. Prometheus).

  Consuming metrics:
  - Start unpoller with `unpoller`, then scrape `http://127.0.0.1:9130/metrics`
    from Prometheus (the wrapper starts a local Prometheus by default).
  - Prometheus UI is available at `http://127.0.0.1:9090`.
  - Grafana UI is available at `http://127.0.0.1:3000` (anonymous viewer; login disabled).
  - Dashboards are available on Grafana.com.

  Why a wrapper:
  - `unpoller` here is a convenience wrapper that injects the token and logging.
  - Use `unpoller --raw -- <args>` to call the upstream binary directly.

  References:
  - Unpoller project: https://github.com/unpoller/unpoller
  - Configuration reference: https://github.com/unpoller/unpoller/wiki/Configuration
  - Prometheus output: https://unpoller.com
  - UniFi API (community): https://ubntwiki.com/products/software/unifi-controller/api
  - Grafana dashboards: https://grafana.com/dashboards?search=unpoller
*/

let
  dashboardsPath = pkgs.linkFarm "unpoller-dashboards" [
    {
      name = "11310-unifi-poller-client-dpi-prometheus.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/11310/revisions/5/download";
        sha256 = "0n63l0x5w35i93w4sgp9hlk7il3pyfcbny37zwcbkq4cv0ifqwcr";
      };
    }
    {
      name = "11311-unifi-poller-network-sites-prometheus.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/11311/revisions/5/download";
        sha256 = "0pwz5fdp4ybfgjnydip6p6wy2siikcg0ikz9li65pmwwmawx49mb";
      };
    }
    {
      name = "11312-unifi-poller-usw-insights-prometheus.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/11312/revisions/9/download";
        sha256 = "1v82bzp5m6zvmvjcchd3704rsd0pg3190lvjpsy0zq883dzz94m1";
      };
    }
    {
      name = "11313-unifi-poller-usg-insights-prometheus.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/11313/revisions/9/download";
        sha256 = "0ldngl8rpqkcx6y5qna4w4pl9b91ksfrnxk4lmllj2wlihkvfzzb";
      };
    }
    {
      name = "11314-unifi-poller-uap-insights-prometheus.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/11314/revisions/10/download";
        sha256 = "1g1chjl1zm24l3an3jam0svrbq29k8166699c2467zy2kbgsq0nv";
      };
    }
    {
      name = "11315-unifi-poller-client-insights-prometheus.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/11315/revisions/9/download";
        sha256 = "1rf60hb5daxha3fiz2j53yrw7hk6rmwg798siiykn8zkjqkmjgz9";
      };
    }
  ];
  unpollerWrapper = pkgs.writeShellScriptBin "unpoller" ''
    #!/bin/sh
    set -eu

    export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin"
    umask 077

    op_path=""
    log_dir="$(pwd)"
    raw_mode="false"
    start_prometheus="true"
    start_grafana="true"

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --raw)
          raw_mode="true"
          shift
          break
          ;;
        --no-prometheus)
          start_prometheus="false"
          shift
          ;;
        --no-grafana)
          start_grafana="false"
          shift
          ;;
        --op-path)
          if [ "$#" -lt 2 ]; then
            echo "Missing value for --op-path" >&2
            exit 2
          fi
          op_path="$2"
          shift 2
          ;;
        --log-dir)
          if [ "$#" -lt 2 ]; then
            echo "Missing value for --log-dir" >&2
            exit 2
          fi
          log_dir="$2"
          shift 2
          ;;
        -h|--help)
          echo "Usage: unpoller --op-path <op://...> [--log-dir <dir>]"
          echo "       unpoller --no-prometheus --op-path <op://...>"
          echo "       unpoller --no-grafana --op-path <op://...>"
          echo "       unpoller --raw -- <args>"
          exit 0
          ;;
        *)
          echo "Unknown argument: $1" >&2
          exit 2
          ;;
      esac
    done

    if [ "$raw_mode" = "true" ]; then
      exec ${pkgs.unpoller}/bin/unpoller "$@"
    fi

    if [ -z "$op_path" ]; then
      if [ -n "''${UNPOLLER_OP_PATH-}" ]; then
        op_path="$UNPOLLER_OP_PATH"
      else
        echo "Missing --op-path or UNPOLLER_OP_PATH" >&2
        exit 2
      fi
    fi

    config_dir="$HOME/Library/Application Support/unpoller"
    mkdir -p "$config_dir"
    config_file="$(mktemp "$config_dir/up.conf.XXXXXX")"
    mkdir -p "$log_dir"

    cleanup() {
      if [ -n "''${prom_pid-}" ]; then
        kill "$prom_pid" 2>/dev/null || true
      fi
      if [ -n "''${grafana_pid-}" ]; then
        kill "$grafana_pid" 2>/dev/null || true
      fi
      rm -f "$config_file"
      if [ -n "''${prom_config-}" ]; then
        rm -f "$prom_config"
      fi
      if [ -n "''${grafana_datasource-}" ]; then
        rm -f "$grafana_datasource"
      fi
      if [ -n "''${grafana_dashboards-}" ]; then
        rm -f "$grafana_dashboards"
      fi
      if [ -n "''${grafana_dashboards_data-}" ]; then
        rm -rf "$grafana_dashboards_data"
      fi
    }
    trap cleanup EXIT INT TERM

    api_key="$(op-secret-cache get "$op_path")"

    cat > "$config_file" <<EOF
[poller]
  debug = false
  quiet = false
  plugins = []

[prometheus]
  disable = false
  http_listen = "127.0.0.1:9130"
  ssl_cert_path = ""
  ssl_key_path  = ""
  report_errors = false
  dead_ports = false

[influxdb]
  disable = true

[loki]
  disable = true

[unifi]
  dynamic = false

[unifi.defaults]
  url = "https://192.168.1.39"
  api_key = "''${api_key}"
  sites = ["all"]
  save_sites = true
  verify_ssl = false
EOF

    if [ "$start_prometheus" = "true" ]; then
      prom_data="$log_dir/prometheus-data"
      prom_config="$(mktemp "$config_dir/prometheus.yml.XXXXXX")"

      cat > "$prom_config" <<EOF
global:
  scrape_interval: 30s

scrape_configs:
  - job_name: unpoller
    static_configs:
      - targets: ['127.0.0.1:9130']
EOF

      ${pkgs.prometheus}/bin/prometheus \
        --config.file "$prom_config" \
        --storage.tsdb.path "$prom_data" \
        --web.listen-address "127.0.0.1:9090" \
        >>"$log_dir/prometheus.log" 2>>"$log_dir/prometheus.err.log" &
      prom_pid="$!"
    fi

    if [ "$start_grafana" = "true" ]; then
      grafana_data="$log_dir/grafana-data"
      grafana_logs="$log_dir/grafana-logs"
      grafana_plugins="$log_dir/grafana-plugins"
      grafana_provisioning="$config_dir/grafana-provisioning"
      grafana_datasources_dir="$grafana_provisioning/datasources"
      grafana_dashboards_dir="$grafana_provisioning/dashboards"
      dashboards_src="${dashboardsPath}"
      grafana_dashboards_data="$config_dir/grafana-dashboards"

      mkdir -p "$grafana_data" "$grafana_logs" "$grafana_plugins" "$grafana_datasources_dir" "$grafana_dashboards_dir" "$grafana_dashboards_data"

      grafana_datasource="$grafana_datasources_dir/prometheus.yml"
      grafana_dashboards="$grafana_dashboards_dir/unpoller.yml"

      cat > "$grafana_datasource" <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://127.0.0.1:9090
    isDefault: true
EOF

      for src in "$dashboards_src"/*.json; do
        name="$(basename "$src")"
        sed 's/"''${DS_PROMETHEUS}"/"Prometheus"/g' "$src" > "$grafana_dashboards_data/$name"
      done

      cat > "$grafana_dashboards" <<EOF
apiVersion: 1
providers:
  - name: unpoller
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: $grafana_dashboards_data
EOF

      GF_PATHS_DATA="$grafana_data" \
      GF_PATHS_LOGS="$grafana_logs" \
      GF_PATHS_PLUGINS="$grafana_plugins" \
      GF_PATHS_PROVISIONING="$grafana_provisioning" \
      GF_SERVER_HTTP_ADDR="127.0.0.1" \
      GF_SERVER_HTTP_PORT="3000" \
      GF_AUTH_ANONYMOUS_ENABLED="true" \
      GF_AUTH_ANONYMOUS_ORG_ROLE="Viewer" \
      GF_AUTH_DISABLE_LOGIN_FORM="true" \
      ${pkgs.grafana}/bin/grafana-server \
        --homepath ${pkgs.grafana}/share/grafana \
        >>"$log_dir/grafana.log" 2>>"$log_dir/grafana.err.log" &
      grafana_pid="$!"
    fi

    echo "Unpoller metrics: http://127.0.0.1:9130/metrics"
    if [ "$start_prometheus" = "true" ]; then
      echo "Prometheus UI: http://127.0.0.1:9090"
      echo "Prometheus data: $log_dir/prometheus-data"
    fi
    if [ "$start_grafana" = "true" ]; then
      echo "Grafana UI: http://127.0.0.1:3000 (admin/admin)"
      echo "Grafana data: $log_dir/grafana-data"
    fi
    echo "Logs: $log_dir/unpoller.log $log_dir/unpoller.err.log"
    if [ "$start_prometheus" = "true" ]; then
      echo "Logs: $log_dir/prometheus.log $log_dir/prometheus.err.log"
    fi
    if [ "$start_grafana" = "true" ]; then
      echo "Logs: $log_dir/grafana.log $log_dir/grafana.err.log"
    fi

    ${pkgs.unpoller}/bin/unpoller --config "$config_file" >>"$log_dir/unpoller.log" 2>>"$log_dir/unpoller.err.log"
  '';
in
{
  home.packages = [
    pkgs.grafana
    pkgs.prometheus
    unpollerWrapper
  ];
}
