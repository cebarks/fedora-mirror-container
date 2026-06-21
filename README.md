# fedora-mirror-container

Containerized private Fedora mirror — syncs from an upstream public mirror and serves packages over HTTP.

## What it does

- Syncs the `fedora-enchilada` module (main Fedora packages) for **x86_64** and **aarch64**
- Automatically detects and mirrors the **2 most recent stable Fedora releases**
- Excludes debug packages, source RPMs, and test releases
- Deduplicates identical files across releases via hardlinking
- Serves the mirror over HTTP with proper keepalives and cache headers per Fedora's mirroring guidelines

## Quick start

1. **Find an upstream mirror** that exposes the `fedora-buffet` rsync module:

   ```bash
   # Check the Fedora MirrorManager for mirrors near you:
   # https://mirrormanager.fedoraproject.org/
   
   # Verify a mirror has fedora-buffet:
   rsync rsync://mirror.example.org/
   ```

2. **Configure:**

   ```bash
   cp .env.example .env
   # Edit .env and set RSYNC_REMOTE to your chosen mirror
   ```

3. **Create the mirror directory:**

   ```bash
   sudo mkdir -p /srv/fedora-mirror
   sudo chown 1000:1000 /srv/fedora-mirror
   ```

4. **Start:**

   ```bash
   docker compose up -d
   ```

   The first sync will take a long time (hours to days depending on bandwidth). The nginx container will start serving once the first sync completes.

5. **Check status:**

   ```bash
   docker compose logs -f sync
   ```

## TrueNAS Scale deployment

To deploy as a custom app on TrueNAS Scale:

1. Clone this repo onto your TrueNAS system or copy the `compose.yaml`, `nginx.conf`, and `.env` files
2. Set `MIRROR_DIR` to a dataset path (e.g., `/mnt/pool/fedora-mirror`)
3. Ensure the dataset is owned by UID 1000: `chown 1000:1000 /mnt/pool/fedora-mirror`
4. Deploy via the Custom App feature using the compose file

The sync image is pre-built and pulled from `ghcr.io/cebarks/fedora-mirror-sync:latest` — no build step required.

## Configuration

| Variable | Default | Description |
|---|---|---|
| `RSYNC_REMOTE` | **(required)** | Upstream rsync mirror URL |
| `SYNC_INTERVAL` | `21600` (6h) | Seconds between sync runs |
| `MIRROR_DIR` | `/srv/fedora-mirror` | Host path for mirror data |
| `MIRROR_PORT` | `8080` | Host port for HTTP access |

## Client setup

Point your Fedora machines at the mirror by creating `/etc/yum.repos.d/local-mirror.repo`:

```ini
[fedora-local]
name=Fedora $releasever - $basearch (local mirror)
baseurl=http://<mirror-host>:8080/fedora/linux/releases/$releasever/Everything/$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
priority=1

[updates-local]
name=Fedora $releasever - $basearch - Updates (local mirror)
baseurl=http://<mirror-host>:8080/fedora/linux/updates/$releasever/Everything/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
priority=1
```

## ZFS tuning

If storing mirror data on ZFS, recommended dataset properties:

```bash
zfs set compression=zstd recordsize=1M atime=off <pool>/fedora-mirror
```

Do not enable ZFS dedup — `quick-fedora-hardlink` handles deduplication at the file level without the ARC memory overhead.

## Customization

### Exclude ISOs/images

Add to the `FILTEREXP` in `quick-fedora-mirror.conf`:

```
\.iso|\.img|\.qcow2|\.raw\.xz|\.box
```

### Mirror additional modules

Edit `MODULES` and `MODULEMAPPING` in `quick-fedora-mirror.conf`. For example, to add EPEL:

```sh
MODULES=(fedora-enchilada fedora-epel)
MODULEMAPPING=(fedora-enchilada fedora fedora-epel epel)
```

### Change sync frequency

Set `SYNC_INTERVAL` in your `.env` file. With quick-fedora-mirror, you can sync as often as every 10 minutes — if there are no changes, it returns almost immediately.
