<div align="center">
  <a href="https://opc-router.com/?utm_source=GitHub&utm_medium=HelmChart&utm_campaign=OpcRouterChart">
    <img src="img/opc_router_logo.png" alt="Logo" >
  </a>
    <br />
    <br />
  <h1 align="center">OPC Router Helm Chart</h1>
  <p align="center">
    OPC Router Helm Chart for the deployment of the opc router in a kubernetes cluster.
    <br />
    <a href="https://opc-router.com/?utm_source=GitHub&utm_medium=HelmChart&utm_campaign=OpcRouterChart"><strong>OPC Router</strong></a>
    -
    <a href="https://www.opc-router.com/contact-and-support/?utm_source=GitHub&utm_medium=HelmChart&utm_campaign=OpcRouterChart"><strong>Contact</strong></a>
    <br />
    <br />
  </p>
</div>

# About the Sample
## **Contents**
- [About the Sample](#about-the-sample)
  - [**Contents**](#contents)
  - [General Information](#general-information)
    - [**What is the helm chart doing?**](#what-is-the-helm-chart-doing)
- [Getting Started](#getting-started)
  - [**Prequisites**](#prequisites)
  - [**Installation**](#installation)
  - [**Uninstalling**](#uninstalling)
- [Configuration](#configuration)
  - [**Parameters**](#parameters)
    - [**Global parameters**](#global-parameters)
    - [**Common parameters**](#common-parameters)
    - [**OPCRouter parameters**](#opcrouter-parameters)
  - [**WARNING: MongoDB root password and replica key set**](#warning-mongodb-root-password-and-replica-key-set)
  - [**Redundancy mode**](#redundancy-mode)
    - [**OPC Router redudancy mode**](#opc-router-redudancy-mode)
    - [**MongoDB redundancy mode**](#mongodb-redundancy-mode)
  - [**Loading a project from a git repository**](#loading-a-project-from-a-git-repository)
  - [**Adding extra environment variables**](#adding-extra-environment-variables)

## General Information
> The OPC Router 4 is generally structured in two parts:
> - The Runtime
> - Management with the user interface
>  
> The two components may run on two completely different systems.  
> To set/edit the OPC Router 4, it is connected to the OPC Router Runtime via OPC Router Management, this abstraction allows the settings to be made remotely.
### **What is the helm chart doing?**
- This helm chart will allow deploying the opc router onto any kubernetes cluster.
- There are multiple possible configurations to deploy the opc router this chart allows.

# Getting Started

## **Prequisites**
- Kubernetes 1.12+
- Helm 3.1.0

## **Installation**
[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:
```shell
helm repo add opc-router https://opc-router.github.io/helm-charts
```
If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
<alias>` to see the charts.

To install the chart with the name `my-opcrouter`:
```shell
helm install my-opcrouter opc-router/opc-router \
  --set I_do_accept_the_EULA=true
```
This command will install the opc router with standard settings, as a service with a seperate mongodb container. The mongodb won't require authentification, which is not recommended. Accepting the [End User License Agreement](https://www.opc-router.com/terms-of-use-and-eula/) by setting `I_do_accept_the_EULA` to true is required for the OPCRouter to run.

To deploy this chart with password authetification use this command:
```shell
helm install my-opcrouter opc-router/opc-router \
  --set mongodb.auth.enabled=true \
  --set mongodb.auth.rootPassword=<Your desired root password> \
  --set mongodb.auth.replicaSetKey=<Your desired replicaset key> \
  --set I_do_accept_the_EULA=true
```
Keep in mind that the root password and replicaset key can't be changed once set. When leaving the password and/or replicaset key empty when auth is enabled, the chart will autogenerate the missing secret.

## **Uninstalling**
The chart with the name `my-opcrouter` can simply be uninstalled by executing:
```shell
helm uninstall my-opcrouter
```
However, keep in mind that the persitant volumes of the mongodb container don't get deleted by this. When reinstalling the chart under the same name you will have to use the previous mongodb root password and replica set key or delete the persistant volume beforehand.

# Configuration

## **Parameters**

### **Global parameters**

| Name                       | Description                                                                                                            | Value |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----- |
| `global.imageRegistry`     | Global Docker image registry                                                                                           | `""`  |
| `global.imagePullSecrets`  | Global Docker registry secret names as an array                                                                        | `[]`  |
| `global.storageClass`      | Global StorageClass for Persistent Volume(s)                                                                           | `""`  |
| `global.namespaceOverride` | Override the namespace for resource deployed by the chart, but can itself be overridden by the local namespaceOverride | `""`  |

### **Common parameters**

| Name               | Description                                                                                | Value |
| ------------------ | ------------------------------------------------------------------------------------------ | ----- |
| `nameOverride`     | String to partially override opc-router.fullname template (will maintain the release name) | `""`  |
| `fullnameOverride` | String to fully override opc-router.fullname template                                      | `""`  |

### **OPCRouter parameters**

| Name                              | Description                                                                                             | Value               |
| --------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------- |
| `I_do_accept_the_EULA`            | If this is false the opc router container won't be able to run.                                         | `false`             |
| `image.repository`                | OPC-Router image registry.                                                                              | `opcrouter/service` |
| `image.tag`                       | OPC-Router image tag (immutable tags are recommended).                                                  | `""`                |
| `image.pullPolicy`                | OPC-Router image pull policy.                                                                           | `IfNotPresent`      |
| `envVars`                         | Array of environment variables for the opc router container.                                            | `[]`               |
| `serviceAccount.create`           | Specifies whether a service account should be created.                                                  | `true`              |
| `serviceAccount.annotations`      | Annotations to add to the service account.                                                              | `{}`                |
| `serviceAccount.name`             | Name of the service account to use. If not set and create is true, it is generated using the fullname.  | `""`                |
| `project.projectRepo`             | URL to git repository of a opcrouter4 project. Optional. Empty means no project gets loaded.            | `""`                |
| `project.projectPath`             | Path to the project .rpe file in the repository. Don't begin with '/'. Optional.                        | `""`                |
| `project.configPath`              | Path to a projects configuration file. Optional. Empty means no configuration file gets loaded.         | `""`                |
| `project.auth.ssh_secret`         | An existing secret containing the ssh-key under the key 'project-ssh-key'. Optional.                    | `""`                |
| `project.auth.ssh_key`            | SSH private key for accessing the git repository. Overridden by ssh_secret, Optional.                   | `""`                |
| `project.auth.safe_key`           | If false, the ssh key won't be saved on the cluster and will be deleted from the cluster.               | `true`              |
| `project.persistantVolume.deploy` | If true, deploys a persistant storage volume for the project and runtime db.                            | `true`              |
| `project.persistantVolume.size`   | The size of the persistant volume.                                                                      | `3Gi`               |
| `containerHistoryLimit`           | The size of the history of deployments kept for potential rollbacks.                                    | `10`                |
| `mongodb.deploy`                  | If false, the mongodb container wont be deployed. Useful when using integrated db of opcrouter/runtime. | `true`              |
| `mongodb.replicaCount`            | The number of mongodb pods to deploy. Set to two when using a redundency twin.                          | `1`                 |
| `mongodb.auth.enabled`            | If false, the mongodb won't require any authentification to access.                                     | `false`             |
| `mongodb.auth.existingSecret`     | Existing secret with mongodb credentials (keys: mongodb-root-password, mongodb-replica-set-key).        | `""`                |
| `mongodb.auth.rootPassword`       | Root password for the mongodb. Will override autogenerated or existing one in secret.                   | `""`                |
| `mongodb.auth.replicaKeySet`      | Replica set key for the mongodb. Will override autogenerated or existing one in secret.                 | `""`                |
| `service.enabled`                 | If false, the application won't be reachable from outside the cluster.                                  | `true`              |
| `service.type`                    | Type of the service. Possible values: ClusterIP, NodePort, LoadBalancer.                                | `ClusterIP`         |
| `service.port`                    | Internal port. The service will be reachable under this port inside the cluster.                        | `27017`             |
| `service.nodePort`                | External port. When NodePort, this port will allow external access to the service.                      | `""`                |
| `service.externalIPs`             | External IPs. Reachable under these IPs, when traffic ingresses into cluster with IPs as destination.   | `[]`                |
| `service.loadBalancerIP`          | LoadBalancer IP. Used by some cloud providers to add external load balancers.                           | `""`                |

## **WARNING: MongoDB root password and replica key set**

When using the mongodb container, keep in mind that that the root password and replica key set can only be set once, as upon initial declaration they are stored in a persistent volume. This may be an issue when using automatically deploying the chart using ArgoCD or Flux, as automatic redeployments can cause the root password to be regenerated when not having set static values for them in the values.yaml. This however will only make the database inaccessible to the opc router, as it will use the new passwords, though the mongodb still uses the old initial passwords. Thus it is highly recommended to set mongodb.auth.dbRootPassword and mongodb.auth.dbReplicaKeySet when not manually deploying the chart for testing purposes.

## **Redundancy mode**
The opc router and mongodb deployed by the chart can both be configured to run in redundancy mode, offering increased protection against hardware loss.

### **OPC Router redudancy mode**
Setting the opc router into redundancy mode will cause a second pod with a opc router runtime container to be deployed. This container will load the same project as the main container, but will remain dorment until the main container is unreachable.

The redundancy mode for the opc router is currently not availible and will be enabled at a later date.

### **MongoDB redundancy mode**
By setting the replica count of the mongodb above one, additional pods running the mongodb containers are created. These mongodb containers will connect and copy the primary container, but aren't accessible themself. When the primary container becomes unreachable, a new primary container will be elected, taking its place.

Keep in mind that currently when the primary mongodb changes, external connection to the application can get lost until the original primary pod is again the primary pod.

## **Loading a project from a git repository**
Please refer to [this sample project](https://github.com/OPC-Router/helm-sample-project) on general information of how to deploy a opc router project from a git repository onto a kubernetes cluster using this helm chart.

## **Adding extra environment variables**

To add extra environment variables (useful for inserting into the config.yaml of your project), use the `envVars` property.
```yaml
envVars:
  - <VarName>: "<VarValue>"
```
A helm install command can also be issued with specifiying multiple environment variables:
```shell
$ helm install my-opcrouter opc-router/opc-router \
  --set envVars[0].TESTVAR="successful" \
  --set envVars[1].OtherVariable=42 \
  --set envVars[2].yetAnotherVar=false \
  --set I_do_accept_the_EULA=true
```
