# `observability` role

Deploys the Prometheus + Grafana + node_exporter stack on the lab host and the per-DUT autossh tunnels that surface DUT metrics to Prometheus.

End-user docs: [`docs/configuracion/observabilidad.md`](../../../docs/configuracion/observabilidad.md).

## What it does

- Installs `autossh`, `prometheus`, `prometheus-node-exporter` and `grafana` (from the official Grafana repository).
- For each entry in `observability_duts`:
  - Generates a `dut-metrics-tunnel-<name>.service` systemd unit that maintains an `autossh` forward from `127.0.0.1:<local_port>` on the host to `127.0.0.1:<remote_port>` on the DUT.
  - Drops a Prometheus scrape-job fragment under `/etc/prometheus/jobs.d/<name>.yml` with the labels declared for that DUT.
- Generates the orchestrator scrape job (`/etc/prometheus/jobs.d/orchestrator-host.yml`).
- Renders `/etc/prometheus/prometheus.yml` from `prometheus.yml.j2` and validates it with `promtool`.
- Provisions the Grafana Prometheus datasource and the three dashboard JSONs (`orchestrator-node.json`, `duts-node.json`, `lab-overview.json`) plus the alerting rules under `files/alerting/fcefyn-alerts.yaml`.
- Enables and starts the tunnels, `prometheus`, `prometheus-node-exporter`, and `grafana-server`.

## Variables

| Variable | Default | Description |
|---|---|---|
| `observability_duts` | see `defaults/main.yml` | List of DUTs to scrape. Each item: `name`, `ssh_alias`, `local_port`, `remote_port`, `labels` (dict of `dut`, `firmware`, `target`). |
| `orchestrator_node_exporter` | `127.0.0.1:9100` | Loopback bind address for the host's node_exporter. |
| `grafana_public_tunnel` | (object) | Configures the reverse SSH tunnel to the Oracle VPS that exposes Grafana over HTTPS. |
| `grafana_config` | (object) | grafana.ini settings: root URL, cookie_secure, anonymous access. |

## Prerequisites

The DUT-side exporter is **not** installed by this role. Each DUT needs a one-time manual setup over SSH:

```sh
opkg install prometheus-node-exporter-lua prometheus-node-exporter-lua-openwrt
uci set prometheus-node-exporter-lua.main.listen_interface='loopback'
uci commit prometheus-node-exporter-lua
/etc/init.d/prometheus-node-exporter-lua enable
/etc/init.d/prometheus-node-exporter-lua start
```

The `setup_dut_exporter.py` script in `scripts/` automates this over parallel SSH. See `docs/operar/setup-dut-exporter.md`.

## Files

- `defaults/main.yml` — DUT list and Grafana / tunnel config.
- `tasks/main.yml` — provisioning logic, package install, dashboard deployment.
- `handlers/main.yml` — `Restart grafana`, `Restart prometheus`.
- `templates/dut-metrics-tunnel.service.j2` — per-DUT autossh unit.
- `templates/dut-scrape-job.yml.j2` — per-DUT scrape config.
- `templates/orchestrator-scrape-job.yml.j2` — host scrape config.
- `templates/prometheus.yml.j2` — main prometheus.yml.
- `templates/grafana-dashboards-provider.yml.j2` — file-based dashboard provider.
- `templates/grafana-reverse-tunnel.service.j2` — reverse SSH tunnel to the public VPS.
- `files/dashboards/*.json` — provisioned Grafana dashboards.
- `files/alerting/fcefyn-alerts.yaml` — Grafana alert rules.

## Run

```sh
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbook_testbed.yml --tags observability -K
```

After a successful run:

- Prometheus: http://127.0.0.1:9090 (Status → Targets).
- Grafana: http://127.0.0.1:3000 (datasource + three dashboards provisioned).
- Public Grafana: https://fcefyn-testbed.duckdns.org (via Oracle VPS).
