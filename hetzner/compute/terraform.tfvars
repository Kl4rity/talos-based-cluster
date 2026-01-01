# Control plane configuration - matching original create-control-plane.sh script
control_plane_config = {
  server_type = "cx23"
  labels = {
    type = "controlplane"
  }
  locations   = ["hel1", "fsn1", "nbg1"]
  name_prefix = "talos-control-plane-"
}

# Worker configuration
worker_config = {
  enabled     = true
  count       = 1
  server_type = "cx23"
  labels = {
    type = "worker"
  }
  location    = "nbg1"
  name_prefix = "talos-worker-"
}
