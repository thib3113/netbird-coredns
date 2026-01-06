Last check : <!-- START last_run_sync -->`2026-01-06T00:03:43.203Z`<!-- END last_run_sync -->

CoreDNS version : <!-- START latest_release_version -->`1.13.2`<!-- END latest_release_version -->

## Netbird + CoreDNS
This Docker image combines a [Netbird](https://netbird.io/) client with a [CoreDNS](https://coredns.io/) server. 

It allows you to run a powerful and customizable DNS server that is instantly accessible from any peer within your private Netbird network.

The project includes a GitHub Action that automatically checks for new CoreDNS releases daily, builds a multi-architecture image (linux/amd64, linux/arm64), and pushes it to Docker Hub.

Features : 
- **Seamless Integration:** Runs CoreDNS on top of the official `netbirdio/netbird` base image.
- **Always Up-to-Date**: Automatically builds and pushes the latest CoreDNS version.

## How to Use

### Prerequisites
1. A Netbird account and a valid Setup Key
2. .Docker or any container runtime installed.
 
### 1. Prepare the CoreDNS Configuration
You must provide a configuration file for CoreDNS. Create a local directory and place your `Corefile` inside it.

```shell
# Create a directory for your configuration
mkdir ./coredns_config

# Create a basic Corefile
cat <<EOF > ./coredns_config/Corefile
# This is a sample Corefile.
company.lan:5353 {
    errors

    log

    cache 30

    template IN A AAAA company.lan {
        match ^(.*)\.company\.lan\.?$

        answer "{{.Name }} 60 IN CNAME traefik.company.lan."

        fallthrough
    }
}

traefik.company.lan:5353 {
    errors
    log
    cache 30
    forward . 127.0.0.11
}

EOF
```

### 2. Run the Container

You can run the container using either the Docker CLI or Docker Compose.

#### Docker CLI
Replace YOUR_NB_SETUP_KEY with your actual key.
```shell
docker run -d \
  --name netbird-dns \
  --network host \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_ADMIN \
  --cap-add=SYS_RESOURCE \
  -e NB_SETUP_KEY="YOUR_NETBIRD_SETUP_KEY" \
  -v $(pwd)/coredns_config:/etc/coredns \
  -v netbird_state:/var/lib/netbird \
  --restart unless-stopped \
  thib3113/netbird-coredns:latest
```
### **Parameters explained:**
   
- `--network host`: Shares the host's networking stack for better performance and simpler setup.
- `--cap-add`: Adds Linux capabilities required for Netbird to manage the network.
- `-e NB_SETUP_KEY`: Your key to automatically register the peer.
- `-v $(pwd)/coredns_config:/etc/coredns`: Mounts your local configuration directory into the container.
 
### **Docker Compose**
This is the recommended method for easier management.

Create a `docker-compose.yml` file:

```yaml
version: "3.8"

services:
  netbird-coredns:
    image: thib3113/netbird-coredns:latest
    container_name: netbird-dns
    restart: unless-stopped
    hostname: netbird-dns
    network_mode: host
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
      - SYS_RESOURCE
    volumes:
      # Mount your CoreDNS configuration
      - ./coredns_config:/etc/coredns
      - netbird_state:/var/lib/netbird
    environment:
      # Replace with your Netbird Setup Key
      - NB_SETUP_KEY=YOUR_NB_SETUP_KEY
volumes:
  # Defines the named volume for persisting state
  netbird_state:
```


Then, start the service:
```shell
docker-compose up -d
```
### 3. Verify and Use

Once the container is running, the peer will appear in your Netbird admin panel. 

You can then use the Netbird IP of this peer as a DNS server (on port `5353` by default, as defined in your `Corefile`) from any other device on your network.

To test from another peer in the same Netbird network:
```
# Assuming 100.x.x.x is the Netbird IP of your new DNS server
nslookup example.com 100.x.x.x
```

Note: `nslookup` on some systems does not support custom ports. You can use `dig`:
```
dig @100.x.x.x -p 5353 example.com
```
