#!/bin/bash

sudo yum update -y
sudo yum upgrade -y
######## Grafana ########

# Enter insert mode and add repository configuration
cat <<EOF | sudo tee /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# Install Grafana
sudo yum install grafana -y

# Reload systemd daemon
sudo systemctl daemon-reload

# Start Grafana service
sudo systemctl start grafana-server

# Check Grafana service status
#sudo systemctl status grafana-server

# Enable Grafana service to start on boot
sudo systemctl enable grafana-server.service


######## Prometheus ########

# Create prometheus user
sudo useradd --no-create-home prometheus

# Create necessary directories
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# Download and extract Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.37.0/prometheus-2.37.0.linux-amd64.tar.gz
tar xvfz prometheus-2.37.0.linux-amd64.tar.gz

# Copy Prometheus binaries to appropriate locations
sudo cp prometheus-2.37.0.linux-amd64/prometheus /usr/local/bin
sudo cp prometheus-2.37.0.linux-amd64/promtool /usr/local/bin/

# Copy Prometheus configuration files
sudo cp -r prometheus-2.37.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.37.0.linux-amd64/console_libraries /etc/prometheus

# Clean up downloaded files and extracted directory
sudo rm -rf prometheus-2.37.0.linux-amd64.tar.gz prometheus-2.37.0.linux-amd64

# Set ownership and permissions
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus

# Create Prometheus service file
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOF

cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'prometheus'
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# Reload systemd daemon
sudo systemctl daemon-reload

# Start Prometheus service
sudo systemctl start prometheus

# Check Prometheus service status
#sudo systemctl status prometheus

# Enable Prometheus service to start on boot
sudo systemctl enable prometheus.service