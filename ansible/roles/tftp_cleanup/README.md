# `tftp_cleanup` role

Installs a periodic cleanup of stale TFTP symlinks and orphan labgrid auto-upload caches on the lab host.

## Why

Labgrid `stage()` (and our CI staging scripts) push firmware images to `/var/cache/labgrid/<user>/<sha>/` and symlink them from `/srv/tftp/...`. When tests are cancelled or runs abort, the symlinks under `/srv/tftp/` may end up dangling and the per-SHA directories under `/var/cache/labgrid/` accumulate. This role prunes both safely.

## What it does

- Drops a shell script at `/usr/local/sbin/tftp-cleanup` from `tftp-cleanup.sh.j2`. The script:
  - Removes broken symlinks under `tftp_cleanup_tftp_dir`.
  - Deletes orphan cache directories under `tftp_cleanup_cache_dir` (no symlink in the TFTP tree resolves into them) **and** older than `tftp_cleanup_retention_days`.
- Installs a `tftp-cleanup.service` (oneshot) and a `tftp-cleanup.timer` with `OnCalendar=` matching `tftp_cleanup_schedule`.
- Enables the timer.

## Variables

| Variable | Default | Description |
|---|---|---|
| `tftp_cleanup_tftp_dir` | `/srv/tftp` | Root served by `dnsmasq`. Broken symlinks anywhere under here are removed. |
| `tftp_cleanup_cache_dir` | `/var/cache/labgrid` | Labgrid auto-upload target. Orphan `<user>/<sha>/` directories older than retention are removed. |
| `tftp_cleanup_retention_days` | `30` | Minimum age before an orphan cache directory is considered for deletion. |
| `tftp_cleanup_schedule` | `daily` | systemd `OnCalendar=` expression. |
| `tftp_cleanup_dry_run` | `false` | When `true`, the script runs with `--dry-run`: it logs what it would delete but removes nothing. Useful for validating on a fresh host. |

## Run

```sh
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbook_testbed.yml --tags tftp_cleanup -K
```

Verify the timer:

```sh
systemctl list-timers tftp-cleanup.timer
journalctl -u tftp-cleanup.service -n 50
```

Trigger a manual run (one shot):

```sh
sudo systemctl start tftp-cleanup.service
```

## Safety

- The script never removes the `tftp_cleanup_tftp_dir` or `tftp_cleanup_cache_dir` themselves, only files/dirs inside them.
- A cache directory is deleted only when **both** conditions hold: no live symlink resolves into it, **and** mtime is older than the retention threshold.
- Set `tftp_cleanup_dry_run: true` the first time you deploy on a host with existing data to confirm nothing important would be deleted.
