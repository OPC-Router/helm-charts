# OPC-Router 4 Helm Chart

## Parameters

### Global parameters

| Name                       | Description                                                                                                            | Value |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----- |
| `global.imageRegistry`     | Global Docker image registry                                                                                           | `""`  |
| `global.imagePullSecrets`  | Global Docker registry secret names as an array                                                                        | `[]`  |
| `global.storageClass`      | Global StorageClass for Persistent Volume(s)                                                                           | `""`  |
| `global.namespaceOverride` | Override the namespace for resource deployed by the chart, but can itself be overridden by the local namespaceOverride | `""`  |


### Common parameters

| Name                     | Description                                                                                               | Value           |
| ------------------------ | --------------------------------------------------------------------------------------------------------- | --------------- |
| `nameOverride`           | String to partially override opc-router.fullname template (will maintain the release name)                | `""`            |
| `fullnameOverride`       | String to fully override opc-router.fullname template                                                     | `""`            |


### OPCRouter parameters

| Name                                     | Description                                                                                            | Value                  |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------ | ---------------------- |
| `I_do_accept_the_EULA`                   | If this is false the opc router container won't be able to run.                                        | `false`                |
| `image.repository`                       | OPC-Router image registry.                                                                             | `opcrouter/runtime`    |
| `image.tag`                              | OPC-Router image tag (immutable tags are recommended).                                                 | `""`                   |
| `image.pullPolicy`                       | OPC-Router image pull policy.                                                                          | `IfNotPresent`         |
| `serviceAccount.create`                  | Specifies whether a service account should be created.                                                 | `true`                 |
| `serviceAccount.annotations`             | Annotations to add to the service account.                                                             | `{}`                   |
| `serviceAccount.name`                    | Name of the service account to use. If not set and create is true, it is generated using the fullname. | `""`                   |
| `service.type`                           | Type of the service. Possible values: ClusterIP, NodePort, LoadBalancer.                               | `ClusterIP`            |
| `service.port`                           | Internal port. The service will be reachable under this port inside the cluster.                       | `27017`                |
| `service.nodePort`                       | External port. When NodePort, this port will allow external access to the service.                     | `""`                   |
| `project.projectRepo`                    | URL to git repository of a opcrouter4 project. Optional. Empty means no project gets loaded.           | `""`                   |
| `project.projectPath`                    | Path to the project .rpe file in the repository. Don't begin with '/'. Optional.                       | `""`                   |
| `project.configPath`                     | Path to a projects configuration file. Optional. Empty means no configuration file gets loaded.        | `""`                   |
| `project.auth.ssh_secret`                | An existing secret containing the ssh-key under the key 'project-ssh-key'. Optional.                   | `""`                   |
| `project.auth.ssh_key`                   | SSH private key for accessing the git repository. Overridden by ssh_secret, Optional.                  | `""`                   |
| `project.auth.safe_key`                  | If false, the ssh key won't be saved on the cluster and will be deleted from the cluster.              | `true`                 |
| `containerHistoryLimit`                  | The size of the history of deployments kept for potential rollbacks.                                   | `10`                   |
| `mongodb.auth.dbRootPassword`            | Root password for the mongodb. Will override autogenerated or existing one in secret.                  | `""`                   |
| `mongodb.auth.dbReplicaKeySet`           | Replica set key for the mongodb. Will override autogenerated or existing one in secret.                | `""`                   |


### Add extra environment variables

To add extra environment variables (useful for inserting into the config.yaml of your project), use the `EnvVars` property.

```yaml
EnvVars:
  - <VarName>: "<VarValue>"
```