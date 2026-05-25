# Glossary

Key terms used across the FCEFyN testbed documentation.

---

**auto-merge**
: A GitHub Pull Request setting that merges the PR automatically as soon as all required reviews and status checks pass. The CI results pipeline relies on it so the bot PR opened by `collect-lime-results.yml` lands on `develop` without manual intervention. Requires the repo-level "Allow auto-merge" toggle to be on.

**autossh**
: An `ssh` wrapper that monitors the connection and brings it back up when it drops. The lab uses it to keep the SSH tunnels from the host to each DUT's exporter port (`dut-metrics-tunnel-<name>.service`), so when the DUT's VLAN changes during a test, Prometheus recovers the scrape without intervention.

**batman-adv**
: B.A.T.M.A.N. Advanced — a mesh routing protocol implemented as a Linux kernel module. Operates at Layer 2, handling frame forwarding between mesh nodes. Used by LibreMesh for L2 mesh connectivity.

**babeld**
: A distance-vector routing daemon implementing the Babel routing protocol (RFC 8966). Used by LibreMesh for IPv4/IPv6 routing on top of the batman-adv mesh.

**batctl**
: batman-adv CLI. `batctl n` lists neighbors, `batctl o` the originator table, `batctl if` shows which hardware interfaces are attached to the mesh. The `test_mesh.py` tests rely on it to validate that the mesh actually formed.

**conntrack**
: Linux kernel table that tracks network connections (TCP, UDP, etc.) — Netfilter uses it for NAT and stateful filtering. On the orchestrator it fills quickly because of `autossh` tunnels and labgrid SSH proxies; once it approaches the limit (`node_nf_conntrack_entries_limit`), new flows start being dropped.

**dnsmasq**
: Lightweight server that combines DHCP, DNS, and TFTP. The lab uses it to serve initramfs images to DUTs over TFTP at boot, and as DHCP server on some isolated VLANs.

**DUT** (Device Under Test)
: A physical router connected to the lab and managed by Labgrid. Each DUT has a place name (e.g. `belkin_rt3200_1`), a VLAN, serial console, and power control.

**dropbear**
: Lightweight SSH server that ships by default on OpenWrt. Tests SSH into the DUTs through dropbear; `test_dropbear_startup` waits up to 120 s for the daemon to start listening on `0.0.0.0:22` before declaring the DUT ready.

**DTB (Device Tree Blob)**
: Binary file compiled from a `.dts` (Device Tree Source). Describes the hardware to the Linux kernel (memory, CPUs, peripherals, MTD partitions). The CI pipeline patches DTBs to inject the OEM MAC or force the legacy SPI-NAND layout on Belkin RT3200.

**initramfs**
: An in-memory root filesystem loaded by the kernel at boot. Used for CI testing because the device boots from RAM via TFTP — no flash write occurs. The device returns to its previous state on power cycle.

**FIT image (Flattened Image Tree)**
: Image format that U-Boot can boot: combines kernel, DTB, and ramdisk in a single `.itb`. The lime-packages pipeline emits FIT images for the MediaTek targets (Belkin RT3200, BPi-R4, OpenWrt One) and injects `bootargs` so U-Boot uses the initramfs from RAM.

**iperf3**
: Herramienta de medición de throughput TCP/UDP. Los tests virtual-mesh la usan (cuando está instalada en la imagen) para medir el ancho de banda entre nodos del mesh.

**JUnit XML**
: A standard XML format for test results, originally from the Java JUnit framework. pytest generates JUnit XML with `--junitxml`. The dashboard parses these files to show per-test-case results.

**KVM (Kernel-based Virtual Machine)**
: Módulo de Linux que provee virtualización asistida por hardware (`/dev/kvm`). QEMU lo usa para que las VMs corran a velocidad cercana a nativa. El step `enable_kvm.sh` del CI instala una udev rule para darle permisos `rw` al usuario del runner sobre `/dev/kvm`.

**Labgrid**
: Open-source framework for embedded board testing. Manages place reservations, power control, serial console, and SSH access to DUTs. Used to coordinate test access across multiple CI jobs and lab hosts.

**labgrid-bound-connect**
: A script that acts as an SSH ProxyCommand. It uses `socat` to bind a TCP connection to a specific VLAN interface on the lab host, routing SSH traffic to the correct DUT.

**LibreMesh**
: An OpenWrt-based firmware distribution for community mesh networks. Includes batman-adv, babeld, shared-state, and other mesh networking components. The primary firmware under test in this lab.

**lime-packages**
: The GitHub repository (`fcefyn-testbed/lime-packages`) that contains the LibreMesh CI workflow (`build-firmware.yml`). Builds firmware, runs tests, and publishes results.

**ImageBuilder (OpenWrt)**
: Container que arma imágenes de firmware OpenWrt a partir de paquetes precompilados (sin compilar el kernel). El stage `build-image` del workflow lo usa para combinar el feed de lime-packages con el rootfs base por target/release.

**mac80211_hwsim**
: A Linux kernel module that creates virtual IEEE 802.11 (WiFi) radios. Used in combination with vwifi to simulate WiFi connectivity between QEMU VMs without physical hardware.

**node_openwrt_info**
: A Prometheus metric exported by node_exporter (with custom textfile collector or scrape labels) on each DUT, carrying `firmware` and `target` as labels so the Lab Overview dashboard can show what's running on each device.

**node_systemd_unit_state**
: A node_exporter metric describing whether a systemd unit is in a given state (`active`, `failed`, `inactive`, …). Used by the Orchestrator Host dashboard's Lab Services section to assert that `labgrid-exporter.service`, `pdudaemon.service`, and `ser2net.service` are running.

**NTP (Network Time Protocol)**
: Protocolo para sincronizar el reloj del sistema contra peers de tiempo confiables. El orchestrator usa el daemon de tiempo del SO (systemd-timesyncd por default, o chrony si se instala) para mantener el clock alineado. El panel "NTP offset" del dashboard Orchestrator Host monitorea el desvío vía `node_timex_offset_seconds`, métrica que viene del kernel timex y funciona sin importar qué daemon esté corriendo.

**opkg / apk**
: Gestores de paquetes de OpenWrt. `opkg` se usa en releases 24.10.x y anteriores (paquetes `.ipk`); `apk` (apk-tools 3.x) reemplazó a opkg desde 25.12.x con paquetes `.apk` y un índice binario `packages.adb`. El CI tiene que branchear por formato porque las flags de `make image` cambian.

**openwrt-tests**
: The test suite and pytest infrastructure (in `lime-packages`) that defines the test cases for both physical DUTs and virtual mesh nodes.

**OpenWrt SDK**
: Conjunto de toolchains precompilados (uno por arquitectura) que permite compilar paquetes OpenWrt fuera del buildroot completo. El stage `build-feed` del CI lo usa vía `openwrt/gh-action-sdk@v9` para producir los `.ipk` / `.apk` del feed de lime-packages.

**pdudaemon**
: A daemon that controls power to DUTs via relay boards or PDUs. Exposes an HTTP API. The lab uses an Arduino + SSR relay board controlled by pdudaemon.

**PAT (Personal Access Token)**
: A GitHub credential scoped per user. The CI results pipeline uses two fine-grained PATs as repository secrets in `fcefyn_testbed_utils`: `LIME_PACKAGES_TOKEN` (Actions: Read on `lime-packages`, for downloading artifacts) and `BOT_PR_TOKEN` (Contents + Pull Requests: Write on this repo, for opening the auto-merged bot PR).

**place**
: A Labgrid concept representing one testable resource (a DUT with all its attached resources). A place has a name (e.g. `labgrid-fcefyn-belkin_rt3200_1`) and is registered with the coordinator.

**prometheus-node-exporter-lua**
: Reimplementación en Lua de node_exporter, mucho más liviana, pensada para OpenWrt (donde la versión Go no entraría en flash). Los DUTs la corren escuchando en loopback (127.0.0.1:9100); el host la consume vía autossh tunnel.

**QEMU**
: An open-source machine emulator. Used to run LibreMesh x86_64 firmware images as virtual machines for CI mesh tests without physical hardware.

**report.xml**
: The JUnit XML file generated by pytest after a test run. Published to GitHub Pages and parsed by the dashboard to show per-test-case results.

**shared-state-async**
: CLI de LibreMesh para leer y escribir tipos de dato sincronizados entre nodos del mesh. Los hooks bajo `/usr/share/shared-state/hooks/` definen qué se sincroniza (ej. `bat-hosts`: mapeo MAC → hostname LiMe). Los tests `test_mesh_shared_state_sync.py` validan que los datos efectivamente propagan.

**ser2net**
: A daemon that forwards serial ports (USB-to-serial adapters) over TCP. Labgrid uses ser2net to access DUT serial consoles remotely.

**shared-state**
: A LibreMesh subsystem that synchronizes structured data (e.g. hostname→MAC mappings) between mesh nodes. Tests verify that data written on one node propagates to others.

**sysupgrade**
: Utilidad de OpenWrt para flashear una imagen nueva preservando (o no, con `-n`) la configuración UCI. En los tests de CI **no se usa**: las imágenes se cargan vía TFTP en RAM (initramfs), nunca se escribe la flash, así el DUT queda en el mismo estado tras cada test.

**TFTP**
: Trivial File Transfer Protocol. Used to deliver the initramfs kernel image to DUTs at boot via the lab's dnsmasq TFTP server.

**UBI / UBIFS**
: Unsorted Block Image filesystem. The flash layout used by OpenWrt on the Belkin RT3200. Requires a one-time migration from the stock layout before initramfs tests can run.

**UCI (Unified Configuration Interface)**
: Sistema de configuración de OpenWrt: archivos planos bajo `/etc/config/` y la CLI `uci` (`uci show lime-defaults`, `uci set lime.*`, `uci commit`). Los tests usan `uci show` para verificar que LibreMesh aplicó los protos esperados; los workflows manejan la config de cada DUT vía UCI.

**ubus**
: Bus de comunicación entre procesos de OpenWrt (similar a D-Bus pero más liviano). Servicios como netifd, hostapd, dnsmasq exponen métodos JSON. Los tests usan `ubus call system board` para leer el modelo, kernel, distro y revisión del DUT.

**VLAN**
: Virtual LAN. The lab uses VLANs to isolate DUT traffic: VLAN 100–104 for isolated testing, VLAN 200 for mesh mode (DUTs see each other).

**vwifi**
: A virtual WiFi relay tool that forwards mac80211_hwsim frames between QEMU VMs over TCP. Allows VMs on the same host to form a real IEEE 802.11 mesh. See [vwifi setup](diseno/vwifi.md).

**vwifi-server / vwifi-client**
: Pareja de procesos que reenvía frames `mac80211_hwsim` entre VMs QEMU sobre TCP, simulando un medio radio compartido. `vwifi-server` corre en el host del lab y `vwifi-client` adentro de cada VM. Permite formar un mesh real 802.11 sin hardware físico para los tests `test-mesh-qemu`.

**WireGuard**
: A modern VPN protocol. Used to connect the self-hosted CI runner (on the lab's datacenter VM) to the lab host, enabling remote hardware access over an encrypted tunnel.

**create-pull-request (action de CI)**
: GitHub Action de terceros que crea PRs vía la API REST de GitHub en lugar de `git push` + `gh pr create`. La usa `collect-lime-results.yml` con `sign-commits: true` para que los commits del bot queden firmados con la web-flow key de GitHub (aparecen "Verified"). Requiere un PAT con permisos **Contents: write** y **Pull requests: write** sobre este repo, cargado como secret `BOT_PR_TOKEN`; el `GITHUB_TOKEN` por default no alcanza porque la org tiene deshabilitado el toggle "Allow GitHub Actions to create and approve pull requests".

**workflow_dispatch**
: A GitHub Actions trigger that allows manually starting a workflow from the GitHub UI or API, with optional input parameters (e.g. selecting an OpenWrt release version).
