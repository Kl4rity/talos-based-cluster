# Load balancer configuration - matching the original create.sh script
load_balancer_name = "controlplane"
location           = "nbg1"
load_balancer_type = "lb11"

# Labels applied to the load balancer
load_balancer_labels = {
  type = "controlplane"
}

# Service configuration for Kubernetes API
service_listen_port      = 6443
service_destination_port = 6443
service_protocol         = "tcp"

# Target configuration
controlplane_target_label_selector = "type=controlplane"
traefik_target_label_selector = "app.kubernetes.io/name=traefik"

# HTTP service configuration (forwards to Traefik)
http_listen_port = 80
http_destination_port = 8000
http_protocol = "tcp"

# HTTPS service configuration (forwards to Traefik)
https_listen_port = 443
https_destination_port = 8443
https_protocol = "tcp"
