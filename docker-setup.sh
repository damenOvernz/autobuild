#!/usr/bin/env bash
# Gives the locked-down 'autobuild' account its OWN private Docker ("rootless Docker").
# - Completely separate from your main Docker: it can't see, stop or change your live containers.
# - Runs without admin rights; containers can't reach services on this server's localhost.
# Run as your normal user (damen):   bash docker-setup.sh
set -uo pipefail
U=autobuild
H=$(getent passwd "$U" | cut -d: -f6)
say()  { printf "\n\033[1;36m==> %s\033[0m\n" "$*"; }
ok()   { printf "    \033[1;32mOK:\033[0m %s\n" "$*"; }
warn() { printf "    \033[1;33m!!\033[0m %s\n" "$*"; }
[ -z "$H" ] && { echo "No '$U' account - run isolate.sh first."; exit 1; }
[ "$(id -u)" -eq 0 ] && { echo "Run as your normal user, not root."; exit 1; }
UID_A=$(id -u "$U")
RUN="/run/user/$UID_A"
AS() { sudo -iu "$U" env XDG_RUNTIME_DIR="$RUN" DBUS_SESSION_BUS_ADDRESS="unix:path=$RUN/bus" \
         PATH="$H/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" bash -lc "$1"; }

say "Step 1/6: Admin password (needed once)"
sudo -v || exit 1

say "Step 2/6: Installing the pieces rootless Docker needs"
if command -v apt-get >/dev/null; then
  sudo apt-get install -y -qq uidmap dbus-user-session slirp4netns fuse-overlayfs >/dev/null 2>&1 \
    && ok "uidmap, slirp4netns, fuse-overlayfs installed" || warn "Some packages didn't install - continuing"
fi
if ! grep -q "^$U:" /etc/subuid 2>/dev/null; then
  sudo usermod --add-subuids 300000-365535 --add-subgids 300000-365535 "$U" && ok "Gave $U its own range of container user IDs"
else ok "Container user IDs already set"; fi

say "Step 3/6: Letting $U run background services without being logged in"
sudo loginctl enable-linger "$U"
sudo systemctl restart "user@$UID_A.service" 2>/dev/null || sudo systemctl start "user@$UID_A.service" 2>/dev/null
for _ in $(seq 1 20); do
  [ -S "$RUN/bus" ] && break
  sudo -u "$U" XDG_RUNTIME_DIR="$RUN" systemctl --user start dbus.socket >/dev/null 2>&1
  sleep 1
done
if [ -S "$RUN/bus" ]; then ok "Background services ready"; else
  warn "User services didn't start (no $RUN/bus). Details:"
  systemctl status "user@$UID_A.service" --no-pager 2>&1 | tail -n 8
  ls -la "$RUN" 2>&1 | head; exit 1
fi

say "Step 4/6: Installing the private Docker"
if command -v dockerd-rootless-setuptool.sh >/dev/null; then
  ok "Rootless tools already installed system-wide"
elif command -v apt-get >/dev/null && apt-cache policy docker-ce-rootless-extras 2>/dev/null | grep -q 'Candidate: [0-9]'; then
  sudo apt-get install -y -qq docker-ce-rootless-extras >/dev/null 2>&1 && ok "Installed docker-ce-rootless-extras"
else
  echo "    Downloading Docker's rootless bundle into $U's own folder..."
  AS 'curl -fsSL https://get.docker.com/rootless | FORCE_ROOTLESS_INSTALL=1 SKIP_IPTABLES=1 sh' >/tmp/ab-rootless.log 2>&1 \
    && ok "Downloaded into $H/bin" || { warn "Download failed - see /tmp/ab-rootless.log"; tail -n 15 /tmp/ab-rootless.log; exit 1; }
fi

# Ubuntu 24.04+ blocks the trick rootless Docker needs unless rootlesskit is allowed via AppArmor
if [ "$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null)" = "1" ]; then
  for rk in /usr/bin/rootlesskit "$H/bin/rootlesskit"; do
    sudo test -x "$rk" || continue
    name=$(echo "$rk" | sed -e 's@^/@@' -e 's@/@.@g')
    sudo tee "/etc/apparmor.d/$name" >/dev/null <<EOF
abi <abi/4.0>,
include <tunables/global>

"$rk" flags=(unconfined) {
  userns,
  include if exists <local/$name>
}
EOF
    ok "AppArmor permission added for $rk"
  done
  sudo systemctl reload apparmor.service 2>/dev/null || sudo systemctl restart apparmor.service
fi

if ! AS 'systemctl --user is-active --quiet docker'; then
  AS 'dockerd-rootless-setuptool.sh install --force' >/tmp/ab-rootless-setup.log 2>&1 \
    || { warn "Setup failed - last lines:"; tail -n 20 /tmp/ab-rootless-setup.log; exit 1; }
fi
AS 'systemctl --user enable --now docker' >/dev/null 2>&1
if AS 'systemctl --user is-active --quiet docker'; then ok "Private Docker service running (starts automatically after reboots)"
else warn "Private Docker service isn't running:"; AS 'journalctl --user -u docker -n 15 --no-pager' 2>/dev/null; exit 1; fi

say "Step 5/6: Telling AutoBuild to use it"
cfg="$H/autobuild/config.env"
sudo grep -q '^DOCKER_HOST=' "$cfg" || echo "DOCKER_HOST=\"unix://$RUN/docker.sock\"" | sudo tee -a "$cfg" >/dev/null
sudo grep -q '^AB_DOCKER=' "$cfg" || echo 'AB_DOCKER=1' | sudo tee -a "$cfg" >/dev/null
if ! sudo grep -q "^AB_PATH=.*$H/bin" "$cfg"; then
  sudo sed -i "s#^AB_PATH=\"#AB_PATH=\"$H/bin:#" "$cfg"
fi
ok "AutoBuild will use the private Docker for test containers"

say "Step 6/6: Testing"
if AS "export DOCKER_HOST=unix://$RUN/docker.sock; docker run --rm hello-world" 2>&1 | grep -q "Hello from Docker"; then
  ok "Private Docker works (ran a test container)"
else
  warn "Test container didn't run. Details:"; AS "export DOCKER_HOST=unix://$RUN/docker.sock; docker info 2>&1 | tail -n 15"; exit 1
fi
main=$(sudo docker ps -q 2>/dev/null | wc -l)
priv=$(AS "export DOCKER_HOST=unix://$RUN/docker.sock; docker ps -q | wc -l")
ok "Isolation check: your main Docker has $main running containers; the private one sees $priv (it can't see yours)"

cat <<EOT

  ============================================================
   Done. AutoBuild now has its own private Docker for disposable
   test databases and containers. Your live containers are untouched.
   Builds clean up their containers when each phase finishes.
  ============================================================
EOT
