# Configure the Google Cloud provider
provider "google" {
  project = "primal-gear-436812-t0"
  region  = "us-central1"
}

# Data source to check if the GCP instance already exists
data "google_compute_instance" "existing_instance" {
  name = "naruto-server"  # Name of the instance you are checking for
  zone = "us-central1-a"
}

# Conditional logic to create the instance if it doesn't already exist
resource "google_compute_instance" "naruto" {
  count        = length(data.google_compute_instance.existing_instance.self_link) == 0 ? 1 : 0

  name         = "naruto"
  machine_type = "e2-micro"  # Machine type (1 vCPU, 1 GB memory)
  zone         = "us-central1-a"

  # Boot disk image for CentOS 9
  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-stream-9"  # CentOS 9 image from GCP
    }
  }

  # Network interface configuration
  network_interface {
    network = "default"
    access_config {}
  }

  # Metadata for startup script (Optional: Apache web server setup for CentOS 9)
  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    echo "Welcome to Naruto's CentOS 9 web server!" > /var/www/html/index.html
    sudo systemctl start httpd
    sudo systemctl enable httpd
  EOT

  tags = ["http-server"]
}

# Firewall rule to allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]  # Allow all traffic
  target_tags   = ["http-server"]
}

# Output the external IP of the created instance
output "instance_external_ip" {
  value = google_compute_instance.naruto[0].network_interface[0].access_config[0].nat_ip
}
