#!/usr/bin/env bash
set -e

IMAGE="kalilinux/kali-rolling"
NAME="kali-gui"
PORT="6080"

echo "[*] Ensuring image $IMAGE is present..."
docker pull "$IMAGE" >/dev/null

# Ensure the named container exists
CID=$(docker ps -a --filter "name=^/${NAME}$" --format "{{.ID}}" | head -n 1)
if [ -z "$CID" ]; then
  echo "[!] Expected container named $NAME does not exist."
  echo "[!] Do NOT create a new one. Stop here and report this."
  exit 1
fi

echo "[*] Reusing existing container $NAME ($CID)..."
docker start "$NAME" >/dev/null || true

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
  websockify --web=/usr/share/novnc/ 6080 localhost:5901 &
  echo
  echo "[*] Kali VNC is running on :1 (port 5901), noVNC on port 6080."
'

echo
echo "[*] In GitHub Codespaces:"
echo "    1) Open the PORTS panel."
echo "    2) Set port 6080 to Public (globe icon)."
echo "    3) Click the 6080 URL and open /vnc.html if needed."
echo "    4) Click Connect and enter your VNC password."

echo
echo "[*] Open this URL in your browser (Codespaces will map it automatically):"
echo "    http://localhost:6080/vnc_auto.html"
