# Devnode

The project addresses several challenges encountered during Rancher development:
- An x86 machine to build the Rancher image from a development branch.
- A private registry to push images and to allow test setups to pull them seamlessly without being bothered by DockerHub's rate limits.

Instead of starting from scratch, Corral is used to automate the provisioning of a DigitalOcean VM tailored for Rancher development.

This repository contains a Corral package that performs the following tasks:
- Sets up a private Docker registry accessible via a randomly generated address under the provided domain.
- Configures the registry to allow image pulling for everyone while restricting image pushing to the VM where it runs.
- Requests Let's Encrypt certificates to avoid Docker's "certificate signed by unknown authority" error.
- Clones a provided GitHub repository into the VM.
- Installs all necessary tools to build Rancher images.

## Usage Guide

To get started, ensure the following tools are installed on your local machine:

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Corral](https://github.com/rancherlabs/corral)

### Step 1: Configure Corral

Run the following command to configure Corral if it is the first time to use it:

```shell
corral config
```

Use the following commands to configure the required variables for this package. 
The list of variables can be found in the `manifest.yaml` file. 

```shell
corral config vars set digitalocean_token  xxxxx
corral config vars set digitalocean_domain xxxxx
corral config vars set digitalocean_size xxxxx
```  

Modify the `commands` section of the `manifest.yaml` file to change the GitHub repository to be cloned.


### Step 2: Trigger Provisioning

Run the following command to provision the resources:

```shell
corral create devnode . --debug
```  

### Step 3: Retrieve VM and Registry Information

Once the creation is successful, retrieve information about the VM and the private registry using:

```shell
corral vars devnode 
```  

### Step 4: Build and push Rancher images

Run the following commands inside the rancher directory:

```shell
export TAG=v2.10.0-rc3
export REPO=<registry_host>/rancher

time make quick

docker tag $REPO/rancher:$TAG localhost:5000/rancher/rancher:$TAG
docker tag $REPO/rancher-agent:$TAG localhost:5000/rancher/rancher-agent:$TAG
docker push localhost:5000/rancher/rancher:$TAG
docker push localhost:5000/rancher/rancher-agent:$TAG
```

Run the following command to pull images on another VM:

```shell
docker pull <registry_host>/rancher/rancher:$TAG
docker pull <registry_host>/rancher/rancher-agent:$TAG
```


### Step 5: Clean Up Resources

When your work is complete, delete all resources created in DigitalOcean with the following command:

```shell
corral delete devnode
```  


