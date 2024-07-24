#!/bin/bash

# Install dependencies
apt-get update
apt-get install -y docker.io nginx jq

# Copy devopsfetch script
cp devopsfetch.sh /usr/local/bin/devopsfetch.sh
chmod +x /usr/local/bin/devopsfetch.sh

# Copy monitoring script
cp devopsfetch_monitor.sh /usr/local/bin/devopsfetch_monitor.sh
chmod +x /usr/local/bin/devopsfetch_monitor.sh

# Set up systemd service
cp devopsfetch.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable devopsfetch.service
systemctl start devopsfetch.service

# Set up log rotation
cat << EOF > /etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    rotate 5
    weekly
    missingok
    notifempty
    compress
    delaycompress
    create 0644 root root
}
EOF

echo "DevOpsFetch installed successfully!"