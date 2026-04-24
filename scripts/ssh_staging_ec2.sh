#!/usr/bin/env bash
set -euo pipefail

KEY_PATH="${KEY_PATH:-/d/KEYS/sage-ec2-key.pem}"
EC2_USER="${EC2_USER:-ubuntu}"
EC2_HOST="${EC2_HOST:-51.21.135.129}"

exec ssh -i "${KEY_PATH}" "${EC2_USER}@${EC2_HOST}"
