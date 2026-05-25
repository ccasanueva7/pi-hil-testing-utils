# Glossary

Key terms used across the FCEFyN testbed documentation.

---

**auto-merge**
: A GitHub Pull Request setting that merges the PR automatically as soon as all required reviews and status checks pass. The CI results pipeline relies on it so the bot PR opened by `collect-lime-results.yml` lands on `develop` without manual intervention. Requires the repo-level "Allow auto-merge" toggle to be on.

**autossh**
: Wrapper alrededor de `ssh` que monitorea la conexión y la levanta de vuelta cuando se cae. El lab lo usa para mantener los túneles SSH desde el host al puerto del exporter de cada DUT (`dut-metrics-tunnel-<name>.service`), de modo que si la VLAN del DUT cambia durante un test, Prometheus recupera el scrape sin intervención.

**batman-adv**
: B.A.T.M.A.N. Advanced — a mesh routing protocol implemented as a Linux kernel module. Operates at Layer 2, handling frame forwarding between mesh nodes. Used by LibreMesh for L2 mesh connectivity.

**babeld**
: A distance-vector routing daemon implementing the Babel routing protocol (RFC 8966). Used by LibreMesh for IPv4/IPv6 routing on top of the batman-adv mesh.

**batctl**
: CLI de batman-adv. `batctl n` lista vecinos, `batctl o` la tabla de originadores, `batctl if` muestra qué interfaces hardware están unidas al mesh. Los tests `test_mesh.py` lo usan para validar que la malla efectivamente se formó.

**conntrack**
: Tabla del kernel Linux que trackea conexiones de red (TCP, UDP, etc.) — la usa Netfilter para NAT y stateful filtering. En el orchestrator se llena rápido por los túneles `autossh` y los SSH-proxies de labgrid; cuando se acerca al límite (`node_nf_conntrack_entries_limit`), los flujos nuevos empiezan a descartarse.

**dnsmasq**
: Servidor liviano que combina DHCP, DNS y TFTP. El lab lo usa para servir las imágenes initramfs por TFTP a los DUTs al bootear, y como DHCP en algunas VLANs aisladas.

**DUT** (Device Under Test)
: A physical router connected to the lab and managed by Labgrid. Each DUT has a place name (e.g. `belkin_rt3200_1`), a VLAN, serial console, and power control.

**dropbear**
: Servidor SSH liviano que viene por default en OpenWrt. Los tests SSH-ean a los DUTs vía dropbear; `test_dropbear_startup` espera hasta 120 s a que el daemon esté escuchando en `0.0.0.0:22` antes de declarar el DUT listo.

**initramfs**
: An in-memory root filesystem loaded by the kernel at boot. Used for CI testing because the device boots from RAM via TFTP — no flash write occurs. The device returns to its previous state on power cycle.

**JUnit XML**
: A standard XML format for test results, originally from the Java JUnit framework. pytest generates JUnit XML with `--junitxml`. The dashboard parses these files to show per-test-case results.

**Labgrid**
: Open-source framework for embedded board testing. Manages place reservations, power control, serial console, and SSH access to DUTs. Used to coordinate test access across multiple CI jobs and lab hosts.

**labgrid-bound-connect**
: A script that acts as an SSH ProxyCommand. It uses `socat` to bind a TCP connection to a specific VLAN interface on the lab host, routing SSH traffic to the correct DUT.

**LibreMesh**
: An OpenWrt-based firmware distribution for community mesh networks. Includes batman-adv, babeld, shared-state, and other mesh networking components. The primary firmware under test in this lab.

**lime-packages**
: The GitHub repository (`fcefyn-testbed/lime-packages`) that contains the LibreMesh CI workflow (`build-firmware.yml`). Builds firmware, runs tests, and publishes results.

**mac80211_hwsim**
: A Linux kernel module that creates virtual IEEE 802.11 (WiFi) radios. Used in combination with vwifi to simulate WiFi connectivity between QEMU VMs without physical hardware.

**node_openwrt_info**
: A Prometheus metric exported by node_exporter (with custom textfile collector or scrape labels) on each DUT, carrying `firmware` and `target` as labels so the Lab Overview dashboard can show what's running on each device.

**node_systemd_unit_state**
: A node_exporter metric describing whether a systemd unit is in a given state (`active`, `failed`, `inactive`, …). Used by the Orchestrator Host dashboard's Lab Services section to assert that `labgrid-exporter.service`, `pdudaemon.service`, and `ser2net.service` are running.

**openwrt-tests**
: The test suite and pytest infrastructure (in `lime-packages`) that defines the test cases for both physical DUTs and virtual mesh nodes.

**pdudaemon**
: A daemon that controls power to DUTs via relay boards or PDUs. Exposes an HTTP API. The lab uses an Arduino + SSR relay board controlled by pdudaemon.

**PAT (Personal Access Token)**
: A GitHub credential scoped per user. The CI results pipeline uses two fine-grained PATs as repository secrets in `fcefyn_testbed_utils`: `LIME_PACKAGES_TOKEN` (Actions: Read on `lime-packages`, for downloading artifacts) and `BOT_PR_TOKEN` (Contents + Pull Requests: Write on this repo, for opening the auto-merged bot PR).

**place**
: A Labgrid concept representing one testable resource (a DUT with all its attached resources). A place has a name (e.g. `labgrid-fcefyn-belkin_rt3200_1`) and is registered with the coordinator.

**QEMU**
: An open-source machine emulator. Used to run LibreMesh x86_64 firmware images as virtual machines for CI mesh tests without physical hardware.

**report.xml**
: The JUnit XML file generated by pytest after a test run. Published to GitHub Pages and parsed by the dashboard to show per-test-case results.

**ser2net**
: A daemon that forwards serial ports (USB-to-serial adapters) over TCP. Labgrid uses ser2net to access DUT serial consoles remotely.

**shared-state**
: A LibreMesh subsystem that synchronizes structured data (e.g. hostname→MAC mappings) between mesh nodes. Tests verify that data written on one node propagates to others.

**TFTP**
: Trivial File Transfer Protocol. Used to deliver the initramfs kernel image to DUTs at boot via the lab's dnsmasq TFTP server.

**UBI / UBIFS**
: Unsorted Block Image filesystem. The flash layout used by OpenWrt on the Belkin RT3200. Requires a one-time migration from the stock layout before initramfs tests can run.

**VLAN**
: Virtual LAN. The lab uses VLANs to isolate DUT traffic: VLAN 100–104 for isolated testing, VLAN 200 for mesh mode (DUTs see each other).

**vwifi**
: A virtual WiFi relay tool that forwards mac80211_hwsim frames between QEMU VMs over TCP. Allows VMs on the same host to form a real IEEE 802.11 mesh. See [vwifi setup](diseno/vwifi.md).

**WireGuard**
: A modern VPN protocol. Used to connect the self-hosted CI runner (on the lab's datacenter VM) to the lab host, enabling remote hardware access over an encrypted tunnel.

**workflow_dispatch**
: A GitHub Actions trigger that allows manually starting a workflow from the GitHub UI or API, with optional input parameters (e.g. selecting an OpenWrt release version).
