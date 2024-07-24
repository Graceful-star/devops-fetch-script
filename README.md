# devops-fetch-script
# DevOpsfetch Documentation

  Devopsfetch is a versatile script designed to streamline the retrieval and monitoring of essential system information for DevOps tasks. It provides insights into active network ports, Docker containers, Nginx server configurations, and recent user login activity, making it an indispensable asset for system administration and troubleshooting.

## Key Features

1. Active Ports & Services: Displays a structured list of open ports, their associated protocols (TCP/UDP), local addresses, and the processes utilizing them. Filtering by a specific port number is available.
2. Docker Insights: Presents a comprehensive overview of Docker images (repository, tag, ID, creation date, size) and containers (ID, name, status, mapped ports). Detailed inspection of individual containers (ID, name, state, image, mounts) is also supported.
3. Nginx Configuration: Unveils Nginx virtual hosts and their corresponding ports, with the ability to examine specific domain configurations in detail.
4. User Activity: Tracks user login information, including usernames, login times, source addresses (if available), and the terminal used. Filtering by specific users is possible, along with the last 5 login attempts for a user.
5. Time-Based Filtering: Allows you to focus on activities within specific time ranges (e.g., "1h" for 1 hour, "24h" for 24 hours, "7d" for 7 days), enhancing troubleshooting efficiency.
6. Continuous Monitoring: The companion devopsfetch_monitor.sh script enables continuous monitoring and logging of system information to /var/log/devopsfetch.log, providing historical insights for analysis and anomaly detection. This script is designed to run as a systemd service for automated execution.
7. Log Rotation: Includes log rotation through logrotate to manage log file size and prevent excessive storage consumption.
8. Customizable: Output formatting can be tailored to your preferences.

## Installation and Setup

#### 1.1 Prerequisites

   I used an ubuntu instance to test it so you can also use it or any other instance you prefer but Linux is highly recommended.

#### 1.2 Install Dependencies
   Run the commands below;
   ```
   sudo apt update
   sudo apt install -y iproute2 docker.io jq nginx   
   ```

#### 1.3 Install DevOpsFetch

1. Clone the repository and cd into it

   
   ```
   git clone https://github.com/Graceful-star/devops-fetch-script.git
   cd devops-fetch-script
   ```
   
   2. Make the installation script executable
   
     `chmod +x install_devopsfetch.sh`
   
   3. Run the installation script
   
      `sudo ./install_devopsfetch.sh`

This script will:

a. Copy devopsfetch.sh to /usr/local/bin/

b. Set up the systemd service for continuous monitoring

c. Configure log rotation

#### 1.4 Configure Docker
  
  Add your user to the docker group
  
  `sudo usermod -aG docker $USER`

### 2. Usage Examples

DevOpsFetch can be run with various flags:

#### 2.1 Port Information

a. Show all ports: devopsfetch -p

b. Show specific port: devopsfetch -p 80

#### 2.2 Docker Information

a. Show all Docker info: devopsfetch -d

b. Show specific container: devopsfetch -d container_name

##### 2.3 Nginx Information

a. Show all Nginx domains: devopsfetch -n

b. Show specific domain: devopsfetch -n example.com

#### 2.4 User Information

a. Show all users: devopsfetch -u

b. Show specific user: devopsfetch -u username

#### 2.5 Time Range Filtering

Filter results within a time range:

`Copydevopsfetch -p -t "2023-07-01 00:00:00-2023-07-02 00:00:00"`

#### 2.6 Combining Flags

You can combine multiple flags:

`Copydevopsfetch -p -d -n -u`

#### 2.7 Help

For help, use:

`Copydevopsfetch -h`

### 3. Logging Mechanism

#### 3.1 Log Location

Logs are stored in /var/log/devopsfetch.log

#### 3.2 Viewing Logs

To view the latest logs:

`Copytail -f /var/log/devopsfetch.log`

#### 3.3 Log Rotation

Logs are automatically rotated weekly or when they exceed 10MB. The last 5 rotated logs are kept.

#### 3.4 Manually Rotating Logs

To manually rotate logs:

`Copysudo logrotate -f /etc/logrotate.d/devopsfetch`

### 4. Troubleshooting

#### 4.1 Service Status

Check if the service is running:

`Copysudo systemctl status devopsfetch.service`

#### 4.2 Restart Service

If needed, restart the service:

`Copysudo systemctl restart devopsfetch.service`

#### 4.3 Check Permissions

Ensure correct permissions:

```
Copysudo ls -l /usr/local/bin/devopsfetch.sh
sudo ls -l /usr/local/bin/devopsfetch_monitor.sh
```

Both should be executable (-rwxr-xr-x).

#### 4.4 Docker Issues

If Docker commands fail, ensure the Docker daemon is running:

`Copysudo systemctl start docker`

### 5. Uninstallation

To uninstall DevOpsFetch:

```
Copysudo systemctl stop devopsfetch.service
sudo systemctl disable devopsfetch.service
sudo rm /etc/systemd/system/devopsfetch.service
sudo rm /usr/local/bin/devopsfetch.sh
sudo rm /usr/local/bin/devopsfetch_monitor.sh
sudo rm /etc/logrotate.d/devopsfetch  
```