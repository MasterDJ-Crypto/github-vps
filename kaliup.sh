#!/usr/bin/env bash
set -e

IMAGE="kalilinux/kali-rolling"
NAME="kali-gui"
PORT="6080"

echo "[*] Ensuring image $IMAGE is present..."
docker pull "$IMAGE" >/dev/null

# Does the named container exist?
CID=$(docker ps -a --filter "name=^/${NAME}$" --format "{{.ID}}" | head -n 1)

if [ -z "$CID" ]; then
  echo "[!] Expected container named $NAME does not exist."
  echo "[!] Do NOT create a new one here. Stop and report this."
  exit 1
fi

# Check if it already has a 6080 port binding
HAS_PORT=$(docker inspect "$NAME" --format '{{json .HostConfig.PortBindings}}' | grep '"6080/tcp"' || true)

if [ -z "$HAS_PORT" ]; then
  echo "[*] Container $NAME exists but has no 6080 port mapping."
  echo "[*] Committing it to an image and recreating with -p 6080:6080 to keep the same system."

  # Commit current state to a temporary image
  SNAP_IMAGE="${NAME}-snap"
  docker commit "$NAME" "$SNAP_IMAGE" >/dev/null

  # Remove old container
  docker rm "$NAME" >/dev/null

  # Recreate container with port mapping, same name
  CID=$(docker run -d --privileged --name "$NAME" -p 6080:6080 "$SNAP_IMAGE" /bin/bash -c "sleep infinity")
  echo "[*] Recreated $NAME with 6080:6080 mapping (CID $CID)."
else
  echo "[*] Reusing existing container $NAME ($CID) with 6080:6080 mapping..."
  docker start "$NAME" >/dev/null || true
fi

echo "[*] Preparing Kali GUI inside container $NAME..."
docker exec -it "$NAME" bash -lc '
  set -e
  export DEBIAN_FRONTEND=noninteractive

  apt update -y
  apt install -y \
    kali-desktop-xfce \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server \
    novnc websockify \
    dbus-x11

  vncserver -kill :1 >/dev/null 2>&1 || true
  rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

  vncserver :1 -geometry 1280x720 -depth 24

  pkill websockify >/dev/null 2>&1 || true
  # start websockify with nohup so it is not killed when this docker-exec shell exits
  nohup websockify --web=/usr/share/novnc/ 6080 localhost:5901 >/tmp/websockify.log 2>&1 &
  sleep 1
  echo
  echo "[*] Kali VNC is running on :1 (port 5901), noVNC on port 6080."
  echo "[*] noVNC log: /tmp/websockify.log"
'

echo
# Keepalive removed: GitHub Codespaces ignores local background-only processes for "activity".
# Use the repository GitHub Action `.github/workflows/codespace-keepalive.yml` to
# periodically curl the public Codespace URL instead (action added to this repo).

echo
echo "[*] In GitHub Codespaces:"
echo "    1) Open the PORTS panel."
echo "    2) Set port 6080 to Public (globe icon)."
echo "    3) Click the 6080 URL and open /vnc.html or /vnc_auto.html."
echo "    4) Click Connect and enter your VNC password."

echo
echo "[*] Open this URL in your browser (Codespaces will map it automatically):"
echo "    https://jubilant-cod-vx5v56q4qqpfpw9r-6080.app.github.dev/vnc.html"
