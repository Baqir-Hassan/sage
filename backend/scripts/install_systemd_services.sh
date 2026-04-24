#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SYSTEMD_DIR="${BACKEND_DIR}/deploy/systemd"

if [[ ! -d "${SYSTEMD_DIR}" ]]; then
  echo "Systemd templates not found at ${SYSTEMD_DIR}" >&2
  exit 1
fi

sudo cp "${SYSTEMD_DIR}/sage-api.service" /etc/systemd/system/
sudo cp "${SYSTEMD_DIR}/sage-sqs-worker.service" /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable sage-api
sudo systemctl enable sage-sqs-worker
sudo systemctl restart sage-api
sudo systemctl restart sage-sqs-worker

echo "Installed and restarted: sage-api, sage-sqs-worker"
echo "Check status with:"
echo "  sudo systemctl status sage-api"
echo "  sudo systemctl status sage-sqs-worker"
