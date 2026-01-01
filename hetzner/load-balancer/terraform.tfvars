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
target_label_selector = "type=controlplane"
