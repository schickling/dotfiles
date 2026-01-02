# HomeKit Integration via Matterbridge

Home Assistant entities are exposed to Apple HomeKit via the Matter protocol using Matterbridge.

## Architecture

```
Home Assistant (8123) → Matterbridge (8283) → Matter (5540) → Apple Home
```

## Components

| Service | Port | Purpose |
|---------|------|---------|
| Home Assistant | 8123 | Smart home hub |
| Matterbridge | 8283 | Matter bridge (web UI) |
| Matter | 5540 | Protocol for HomeKit |

## Configuration

### Initial Setup (one-time)

1. **Create HA token**: http://homepi:8123 → Profile → Security → Long-Lived Access Tokens

2. **Configure plugin**: http://homepi:8283
   - Install `matterbridge-hass` plugin
   - Set host: `ws://localhost:8123`
   - Set token: (paste HA token)
   - Save & restart

3. **Pair with Apple Home** (if not already paired):
   - Get pairing code from Matterbridge UI → Home tab (shows QR code)
   - Open Apple Home → Add Accessory → Scan QR or enter manual code

## Management

```bash
# Check status
docker ps --filter name=matterbridge

# View logs
docker logs matterbridge --tail 50

# Restart
docker restart matterbridge

# Check HA connection in logs
docker logs matterbridge 2>&1 | grep -i hass
```

## Files

- `/var/lib/matterbridge/` - Matterbridge persistent storage
- `/var/lib/home-assistant/configuration.yaml` - HA config (HomeKit section removed)
- `matterbridge.nix` - NixOS container definition

## Troubleshooting

**Devices not showing in Apple Home**: Restart Matterbridge, check logs for HA connection errors.

**HA connection failed**: Verify token is valid, check `ws://localhost:8123` is reachable from container.

**Need to re-pair**: Reset commissioning via Matterbridge UI → Settings → Reset.

## TODO: Camera support via Matter

Matter does not currently expose cameras to Apple Home. Track these for progress:

- https://github.com/project-chip/connectedhomeip/issues?q=camera
- https://github.com/home-assistant-libs/python-matter-server/issues?q=camera

## Alternatives

If Matterbridge doesn't meet your needs:

- **[Scrypted](https://www.scrypted.app/)**: For HomeKit Secure Video (camera recording to iCloud)
- **[Native HA HomeKit Bridge](https://www.home-assistant.io/integrations/homekit/)**: Simpler but less reliable with Docker
- **[Homebridge](https://homebridge.io/)**: Mature alternative with large plugin ecosystem
