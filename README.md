# fcefyn-testbed-utils

Complementary infrastructure for the FCEFyN HIL (Hardware-in-the-Loop) testbed: configs, Ansible roles, scripts, dashboards, and firmwares that are not part of the contributed repositories [`libremesh-tests`](https://github.com/fcefyn-testbed/libremesh-tests) and [`aparcar/openwrt-tests`](https://github.com/aparcar/openwrt-tests).

## Links

- **Documentation site:** <https://fcefyn-testbed.github.io/fcefyn_testbed_utils/>
- **CI Test Dashboard:** <https://fcefyn-testbed.github.io/fcefyn_testbed_utils/ci-results/dashboard.html>
- **Public Grafana (lab metrics):** <https://fcefyn-testbed.duckdns.org>

---

## What is in this repository

| Directory | Contents |
|---|---|
| `ansible/` | Idempotent provisioning for the lab host: observability stack, WireGuard, ZeroTier, PoE switch / Arduino relay control, TFTP cleanup, WoL, virtual-mesh. See [`ansible/roles/`](ansible/roles/). |
| `configs/` | Templates and example configs (udev rules, ssh config, switch credentials). |
| `docs/` | MkDocs site source (lab operations, configuration, design, CI dashboard, glossary). |
| `scripts/` | Operator helpers (DUT exporter setup, switch control, mesh-IP provisioning, gateway management). |
| `.github/workflows/` | CI: docs Pages deploy, lint, scheduled `collect-lime-results` workflow that pulls JUnit reports from `lime-packages` CI. |
| `tests/` | Local pytest suites used during development (virtual mesh scaffolding). |

## Quick start

### Browse the docs (live or local)

- Live: <https://fcefyn-testbed.github.io/fcefyn_testbed_utils/>.
- Local preview with MkDocs (includes `mkdocs-panzoom-plugin` for Mermaid pan/zoom):

  ```bash
  python3 -m venv .venv-docs
  source .venv-docs/bin/activate           # Windows: .venv-docs\Scripts\activate
  pip install -r requirements-docs.txt
  mkdocs serve                              # or: mkdocs serve --livereload
  ```

  If `mkdocs serve` reports `The "panzoom" plugin is not installed`, the active venv is missing dependencies — rerun `pip install -r requirements-docs.txt`.

### Provision a fresh lab host (Ansible)

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbook_testbed.yml -K
```

Or restrict to a single role:

```bash
ansible-playbook ... --tags observability -K
ansible-playbook ... --tags wireguard -K
```

Each role has its own README under [`ansible/roles/<role>/README.md`](ansible/roles/) with variables, prerequisites, and verification steps.

### Open the CI dashboard

<https://fcefyn-testbed.github.io/fcefyn_testbed_utils/ci-results/dashboard.html>

Shows the status, run history, and per-test breakdown of every `build-firmware.yml` job in `fcefyn-testbed/lime-packages`. Results are pulled in by the `collect-lime-results` workflow every 6 hours.

## Documentation map

The docs site is organised in four top-level sections:

- **Lab operations** — day-to-day procedures (running tests, SSH access, DUT onboarding, debugging FAQ).
- **Component configuration** — host, switch, gateway, DUTs, Ansible / Labgrid, observability stack.
- **Design** — integration overview, lab architecture, CI flows (`openwrt-tests`, `lime-packages` build + tests + governance), QEMU and vwifi setup.
- **CI Test Dashboard** — overview, architecture, device registry, publishing pipeline, usage, maintenance.

Plus a **Glossary** of testbed and mesh networking terms.

## Related repositories

| Repo | Role |
|---|---|
| [`fcefyn-testbed/libremesh-tests`](https://github.com/fcefyn-testbed/libremesh-tests) | Pytest suite + Labgrid target files. Checked out by the `lime-packages` CI workflow during test jobs. |
| [`fcefyn-testbed/lime-packages`](https://github.com/fcefyn-testbed/lime-packages) | LibreMesh fork containing the build + test CI pipeline; produces firmware images and per-job `report.xml` artifacts. |
| [`aparcar/openwrt-tests`](https://github.com/aparcar/openwrt-tests) | Upstream remote-lab framework that this testbed contributes a lab to. |

## Contributing

This repository follows GitHub-flow style: branches off `develop`, PRs to `develop`, periodic `develop → main` syncs.

- Required: signed commits (GPG), passing `lint` workflow.
- The `develop` and `main` branches have protection rules — direct pushes are blocked, changes land via PR.
- Auto-merge is allowed; the `collect-lime-results` workflow relies on it.

See [`docs/configuracion/ci-runner.md`](docs/configuracion/ci-runner.md) for self-hosted runner setup and [`docs/ci-results/maintenance.md`](docs/ci-results/maintenance.md) for the CI dashboard maintenance procedures (token rotation, manual triggers, troubleshooting).
