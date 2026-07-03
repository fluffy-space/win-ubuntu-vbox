# TODO

- [ ] **Version upgrade/update script (PHP, Swoole).** A `scripts/upgrade.sh` that
  rebuilds PHP and/or Swoole to a newer release on an already-provisioned box —
  without re-running the full `server.sh`. Should:
  - Take target versions (`--php <ver>`, `--swoole <ver>`), defaulting to the
    latest stable (resolve via the php-src / swoole-src GitHub release tags).
  - Download, build (`make -j$(nproc)`), and `make install` into place; reuse the
    same `./configure` flags as `server.sh`.
  - Preserve `/usr/local/lib/php.ini` and re-append the `extension=` lines only if
    missing (inotify, redis, swoole).
  - Back up the current binaries/ini before swapping; verify `php -v` and the
    loaded Swoole version afterward and roll back on failure.
  - Restart the app + Caddy/nginx after a successful upgrade.
  - Keep the `PHP_VER` / `SWOOLE_VER` defaults in `server.sh` in sync (single
    source of truth, or share a small `versions.env`).
