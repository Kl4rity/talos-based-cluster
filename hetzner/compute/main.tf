locals {
  control_plane_user_data = file("../talos/controlplane.yaml")
}

resource "hcloud_server" "control_plane_nodes" {
  for_each = { for i, location in var.control_plane_config.locations : i => location }
  
  name       = "${var.control_plane_config.name_prefix}${each.key + 1}"
  image      = var.image_id
  server_type = var.control_plane_config.server_type
  location   = each.value
  labels     = var.control_plane_config.labels
  user_data  = local.control_plane_user_data
}