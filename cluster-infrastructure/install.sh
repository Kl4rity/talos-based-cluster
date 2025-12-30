#!/bin/bash
set -euo pipefail

helmfile sync
helmfile status
