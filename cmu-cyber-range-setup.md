# Setting up the SEI CMU Cyberrange with ESXi
#### This guide was written with using VMWare ESXi Version 7 Update 3
##### Hardware Specifications: Intel Exeon E5-2695 @2.30 GHz, 3 TB RAID 6, and 132 GB of RAM
##### Contents can be found in https://github.com/cmu-sei/foundry-appliance
## Installing a Nested ESXi, Foundry OVA, and configuring Scripts loaded
### Install the Nested ESXi
The first step would be looking into installing a nested ESXi. Nested ESXis can be easily installed and deployed into the server. Install ESXi that matches the server's version: `https://williamlam.com/nested-virtualization/nested-esxi-virtual-appliance`

Set a chosen volume disk to at least 100 GBs as this VM server will be holding the devices

**DO  NOT SET THE SYSTEM TO BOOT AUTOMATICALLY**

Go into the ESXi shell by remoting in with the main ESXi's IP Address and login credentials. 

Go into `/vmfs/volumes/[Insert Datastore name here]/[Insert Virtual Machine Name] `:  

Run `vi [Insert Virtual Machine Name].vmx` and insert these two lines at the end of the .vmx file


    guestinfo.ssh = "TRUE"
    guestinfo.createvmfs = "TRUE"`
This will enable the ESXi SSH daemon and create a new VMFS datastore from the largest disk in the appliance.

After inserting the two lines inside your .vmx file, boot up the nested ESXi.
### Deploy the Foundry OVA
The second step looking is installing your OVA from the foundry appliance repository. For a easy and quick install, go through the process of visiting the github and installing the latest OVA. 

Drop it into your server's ESXi client and now the website can be accessed through:
`https://foundry.local`

### Configuring Scripts to your individual client
#### ONLY FOLLOW THESE STEPS IF THE SCRIPTS ARE NOT PERFORMING PROPERLY, IF IT IS, DISREGARD
* Change to the /foundry/foundry/certs directory and run the *generate-certs* script
* Edit the setup-esxi script and find lines 17,18, and 19. It should look like this:

        RUI_CRT=$(cat ../certs/host.pem ../certs/int-ca.pem)
        RUI_KEY=$(<certs/host-key.pem)
        APPLIANCE_IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

* Change the RUI_CRT, RUI_KEY, APPLIANCE_IP variable to the full directory of the certs, here's an example:
    
        RUI_CRT = /home/foundry/foundry/certs/host.pem /home/foundry/foundry/certs/int-ca.pem
        RUI_KEY = /home/foundry/foundry/certs/host-key.pem
        APPLIACE_IP =**INSERT THE IP ADDRESS OF THE APPLIANCE**
      
* Edit the import-content script on line 115, and rewrite it by only leaving one postgres:

The original:

        kubectl exec --stdin --tty postgresql-postgresql-0 \
The edited:
       
        kubectl exec --stdin --tty postgresql-0 \
### Import the Presidents Cup json file with the import-content script and access TopoMojo through Foundry Local. Then the VMs should now be accessible. Any future references and directions from here would be on the foundry docs repository inside the CMU SEI GitHub
