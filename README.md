# OPC-Router 4 Helm Chart

## Prequisites
- Kubernetes 1.12+
- Helm 3.1.0

## Installation
To install the chart with the name `my-opcrouter`:
```shell
$ helm install my-opcrouter <Path> --set I_do_accept_the_EULA=true
```
This command will install the opc router with standard settings, as a service with a seperate mongodb container. Accepting the [End User License Agreement](https://www.opc-router.com/terms-of-use-and-eula/) by setting `I_do_accept_the_EULA` to true is required for the OPCRouter to run.

## Uninstalling
The chart with the name `my-opcrouter` can simply be uninstalled by executing:
```shell
$ helm uninstall my-opcrouter
```
However, keep in mind that the persitant volumes of the mongodb container don't get deleted by this. When reinstalling the chart under the same name you will have to use the previous mongodb root password and replica set key or delete the persistant volume beforehand.

## Parameters

### Global parameters

| Name                       | Description                                                                                                            | Value |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----- |
| `global.imageRegistry`     | Global Docker image registry                                                                                           | `""`  |
| `global.imagePullSecrets`  | Global Docker registry secret names as an array                                                                        | `[]`  |
| `global.storageClass`      | Global StorageClass for Persistent Volume(s)                                                                           | `""`  |
| `global.namespaceOverride` | Override the namespace for resource deployed by the chart, but can itself be overridden by the local namespaceOverride | `""`  |

### Common parameters

| Name               | Description                                                                                | Value |
| ------------------ | ------------------------------------------------------------------------------------------ | ----- |
| `nameOverride`     | String to partially override opc-router.fullname template (will maintain the release name) | `""`  |
| `fullnameOverride` | String to fully override opc-router.fullname template                                      | `""`  |

### OPCRouter parameters

| Name                                         | Description                                                                                             | Value               |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------- |
| `I_do_accept_the_EULA`                       | If this is false the opc router container won't be able to run.                                         | `false`             |
| `image.repository`                           | OPC-Router image registry.                                                                              | `opcrouter/service` |
| `image.tag`                                  | OPC-Router image tag (immutable tags are recommended).                                                  | `""`                |
| `image.pullPolicy`                           | OPC-Router image pull policy.                                                                           | `IfNotPresent`      |
| `serviceAccount.create`                      | Specifies whether a service account should be created.                                                  | `true`              |
| `serviceAccount.annotations`                 | Annotations to add to the service account.                                                              | `{}`                |
| `serviceAccount.name`                        | Name of the service account to use. If not set and create is true, it is generated using the fullname.  | `""`                |
| `project.projectRepo`                        | URL to git repository of a opcrouter4 project. Optional. Empty means no project gets loaded.            | `""`                |
| `project.projectPath`                        | Path to the project .rpe file in the repository. Don't begin with '/'. Optional.                        | `""`                |
| `project.configPath`                         | Path to a projects configuration file. Optional. Empty means no configuration file gets loaded.         | `""`                |
| `project.auth.ssh_secret`                    | An existing secret containing the ssh-key under the key 'project-ssh-key'. Optional.                    | `""`                |
| `project.auth.ssh_key`                       | SSH private key for accessing the git repository. Overridden by ssh_secret, Optional.                   | `""`                |
| `project.auth.safe_key`                      | If false, the ssh key won't be saved on the cluster and will be deleted from the cluster.               | `true`              |
| `project.persistantVolume.deploy`            | If true, deploys a persistant storage volume for the project and runtime db.                            | `true`              |
| `project.persistantVolume.size`              | The size of the persistant volume.                                                                      | `3Gi`               |
| `containerHistoryLimit`                      | The size of the history of deployments kept for potential rollbacks.                                    | `10`                |
| `mongodb.deploy`                             | If false, the mongodb container wont be deployed. Useful when using integrated db of opcrouter/runtime. | `true`              |
| `mongodb.replicaCount`                       | The number of mongodb pods to deploy. Set to two when using a redundency twin.                          | `1`                 |
| `mongodb.auth.enabled`                       | If false, the mongodb won't require any authentification to access.                                     | `true`              |
| `mongodb.auth.dbRootPassword`                | Root password for the mongodb. Will override autogenerated or existing one in secret.                   | `""`                |
| `mongodb.auth.dbReplicaKeySet`               | Replica set key for the mongodb. Will override autogenerated or existing one in secret.                 | `""`                |
| `mongodb.externalAccess.enabled`             | If false, the application won't be reachable from outside the cluster.                                  | `true`              |
| `mongodb.externalAccess.service.type`        | Type of the service. Possible values: ClusterIP, NodePort, LoadBalancer.                                | `ClusterIP`         |
| `mongodb.externalAccess.service.port`        | Internal port. The service will be reachable under this port inside the cluster.                        | `27017`             |
| `mongodb.externalAccess.service.nodePorts`   | External ports. When NodePort, the ports configured here will allow external access to the service.     | ` -`                |

### WARNING: MongoDB root password and replica key set

When using the mongodb container, keep in mind that that the root password and replica key set can only be set once, as upon initial declaration they are stored in a persistent volume. This may be an issue when using automatically deploying the chart using ArgoCD or Flux, as automatic redeployments can cause the root password to be regenerated when not having set static values for them in the values.yaml. This however will only make the database inaccessible to the opc router, as it will use the new passwords, though the mongodb still uses the old initial passwords. Thus it is highly recommended to set mongodb.auth.dbRootPassword and mongodb.auth.dbReplicaKeySet when not manually deploying the chart for testing purposes.

### Add extra environment variables

To add extra environment variables (useful for inserting into the config.yaml of your project), use the `EnvVars` property.

```yaml
EnvVars:
  - <VarName>: "<VarValue>"
```