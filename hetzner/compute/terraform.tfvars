# Control plane configuration - matching original create-control-plane.sh script
control_plane_config = {
  server_type = "cx21"
  labels = {
    type = "controlplane"
  }
  locations   = ["hel1", "fsn1", "nbg1"]
  name_prefix = "talos-control-plane-"
}
