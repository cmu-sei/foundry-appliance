# Proxmox Setup



### Part One: Appliance Setup

1. Download the latest release of the appliance from:  
   [https://github.com/cmu-sei/foundry-appliance](https://github.com/cmu-sei/foundry-appliance)

2. Import the appliance into Proxmox:
   - Log in to the Proxmox web interface.
   - Select **Datacenter**, then navigate to the **Storage** section.
   - Select **local** and click **Edit**.
   - Under **Content**, enable **Disk Image** and **ISO image**, then click **OK**.
   - In the left pane, expand **local** and go to the **ISO Images** tab.
   - Click **Upload**, select your `.ova` file, and upload it.
   - After upload, go to **local** > **Content**, locate the `.ova`, and select **Import**.
   - Accept the default import options and start the import.
   - While this is running, you may proceed to Part Two.

---

### Part Two: Configure Proxmox & TopoMojo

1. **Create an Access Token**
   - In the Proxmox Web UI, go to:  
     **Datacenter** → **Permissions** → **API Tokens**
   - Select the `root` user and uncheck **Privilege Separation**.
   - Copy the **Token ID** and **Secret**; they’ll be used later.

2. **Create an SDN Zone**
   - In the Proxmox Web UI:  
     **Datacenter** → **SDN** → **Zones**
   - Click **Add**, choose **VXLAN** as the type.
   - Note the **ID** — this will be referenced in TopoMojo config.
   - Under **Peers**, list the IP addresses (comma-separated) of all cluster nodes.
   - Any new nodes added later must also be added to this zone.

3. **Configure NGINX on the Proxmox instance**
   - On the primary Proxmox node, install NGINX:

     ```bash
     apt update
     apt install nginx
     systemctl enable nginx
     ```

   - Remove the default site:

     ```bash
     rm -f /etc/nginx/sites-enabled/default
     ```

   - Create a new file `/etc/nginx/sites-available/proxmox.conf` with the following content:

     ```nginx
     upstream proxmox {
         server "pve.local";
     }

     server {
         listen 80 default_server;
         rewrite ^(.*) https://$host$1 permanent;
     }

     server {
         listen 443;
         server_name _;

         ssl on;
         ssl_certificate /etc/pve/local/pve-ssl.pem;
         ssl_certificate_key /etc/pve/local/pve-ssl.key;
         proxy_redirect off;

         location ~ /api2/json/nodes/.+/qemu/.+/vncwebsocket.* {
             proxy_set_header "Authorization" "PVEAPIToken=<api_token>";
             proxy_http_version 1.1;
             proxy_set_header Upgrade $http_upgrade;
             proxy_set_header Connection "upgrade";
             proxy_pass https://localhost:8006;
             proxy_buffering off;
             client_max_body_size 0;
             proxy_connect_timeout 3600s;
             proxy_read_timeout 3600s;
             proxy_send_timeout 3600s;
             send_timeout 3600s;
         }

         location / {
             proxy_http_version 1.1;
             proxy_set_header Upgrade $http_upgrade;
             proxy_set_header Connection "upgrade";
             proxy_pass https://localhost:8006;
             proxy_buffering off;
             client_max_body_size 0;
             proxy_connect_timeout 3600s;
             proxy_read_timeout 3600s;
             proxy_send_timeout 3600s;
             send_timeout 3600s;
         }
     }
     ```

   - Replace `"pve.local"` with your custom name, e.g., `"proxmox.foundry.local"`.
     - This is required to match the appliance's certificate structure.
     - Example: `proxmox.foundry.local`

   - Insert your API token in this format:

     ```
     root@pam!foundry=efae52e5-2650-41a7-8486-71bb050ea9d5
     ```

   - Create the symlink:

     ```bash
     ln -s /etc/nginx/sites-available/proxmox.conf /etc/nginx/sites-enabled/proxmox.conf
     ```

   - Test and reload NGINX:

     ```bash
     nginx -t
     systemctl reload nginx
     ```

---

### Part Three: Configure DNS and SSL Certs

This step sets the Proxmox hostname, ensures local DNS resolution, and installs the appliance-generated SSL certificates.

> This process is also scripted and stored in:  
> `scripts/proxmox-setup.sh`
>
> For the purpose of explanation, it is assumed you wish to name your Proxmox instance proxmox.foundry.local

1. **Update your local `/etc/hosts`**
    ```bash
    echo "<proxmox-ip> proxmox.foundry.local" >> /etc/hosts
    ```

2. **Set the Proxmox hostname and update `/etc/hosts`**
    - SSH into the Proxmox node:

    ```bash
    ssh root@proxmox.foundry.local
    ```

    - Set the system hostname:

    ```bash
    hostnamectl set-hostname proxmox.foundry.local
    ```

    - Overwrite the contents of `/etc/hostname`:

    ```bash
    echo "proxmox.foundry.local" > /etc/hostname
    ```

    - Add the IP mapping to `/etc/hosts` (replace `<proxmox-ip>` with the actual IP):

    ```bash
    echo "<proxmox-ip> proxmox.foundry.local proxmox" >> /etc/hosts
    ```

3. **Install appliance-generated SSL certificates**

These certificates are required by the appliance and must match the `.foundry.local` domain.

- From the appliance, copy the certificate files to the Proxmox node:

  ```bash
  scp /home/foundry/foundry/certs/host.pem root@proxmox.foundry.local:/tmp/
  scp /home/foundry/foundry/certs/host-key.pem root@proxmox.foundry.local:/tmp/
  ```

- SSH into the Proxmox node:

  ```bash
  ssh root@proxmox.foundry.local
  ```

- Combine and install the certificates:

  ```bash
  cp /tmp/host.pem /etc/pve/nodes/proxmox/pve-ssl.pem
  cp /tmp/host-key.pem /etc/pve/nodes/proxmox/pve-ssl.key
  ```

- Optionally back up the originals:

  ```bash
  cp /etc/pve/nodes/proxmox/pve-ssl.pem /etc/pve/nodes/proxmox/pve-ssl.pem.orig
  cp /etc/pve/nodes/proxmox/pve-ssl.key /etc/pve/nodes/proxmox/pve-ssl.key.orig
  ```

- Restart Proxmox services:

  ```bash
  systemctl restart nginx
  systemctl restart pveproxy pvedaemon
  ```
---

### Part Four: TopoMojo Configuration

This section covers configuration changes to the TopoMojo values file. These can be configured in TopoMojo's appsettings as well.

> The TopoMojo values file is located at:  
> `/home/foundry/foundry/topomojo.values.yaml`  
>  
> The values that need to be updated can be found under:  
> `topomojo-api -> env`


1. **Required Updates**
   - `Pod__HypervisorType`:  
     Set to `Proxmox`
   - `Pod__Url`:  
     Set to `"proxmox.foundry.local"`
   - `Pod__AccessToken`:  
     Example: `root@pam!foundry=efae52e5-2650-41a7-8486-71bb050ea9d5`
   - `Pod__SDNZone`:  
     Set this to the ID of the SDN Zone configured earlier

2. **Optional Updates**
   - `Pod__Password`:  
     Password of the root user (enables Guest Settings support)
   - `Pod__Vlan__ResetDebounceDuration`:  
     Milliseconds TopoMojo will wait before reloading Proxmox's SDN after a virtual network operation
   - `Pod__Vlan__ResetDebounceMaxDuration`:  
     Maximum debounce duration in milliseconds before TopoMojo reloads Proxmox's SDN

3. **ISO Upload Support**
TopoMojo can optionally allow uploading ISO files to be mounted to virtual machines. To enable this:

   - `Pod__IsoStore`:  
     Name of the shared storage in your Proxmox cluster where ISOs will be stored  
     _Example:_ `iso`

   - `FileUpload_IsoRoot`:  
     Path mounted to the TopoMojo API container where uploaded ISOs will be saved.  
     This should map to the same underlying storage as `Pod__IsoStore`.  
     The path must end in `/template/iso`.  
     _Example:_ `/mnt/isos/template/iso`

   - `FileUpload_SupportsSubFolders`:  
     Set this to `false` — Proxmox does not allow subfolders in ISO stores

---
