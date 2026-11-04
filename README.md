<div align="center">
  <a href="https://opc-router.com/?utm_source=GitHub&utm_medium=HelmChart&utm_campaign=OpcRouterChart">
    <img src="img/opc_router_logo.png" alt="Logo" >
  </a>
    <br />
    <br />
  <h1 align="center">OPC Router Helm Chart</h1>
  <p align="center">
    OPC Router Helm Chart for the deployment of the OPC Router in a kubernetes cluster.
    <br />
    <a href="https://opc-router.com/?utm_source=GitHub&utm_medium=HelmChart&utm_campaign=OpcRouterChart"><strong>OPC Router</strong></a>
    -
    <a href="https://www.opc-router.com/contact-and-support/?utm_source=GitHub&utm_medium=HelmChart&utm_campaign=OpcRouterChart"><strong>Contact</strong></a>
    <br />
    <br />
  </p>
</div>

# About the chart
## **Contents**
- [About the chart](#about-the-chart)
  - [**Contents**](#contents)
  - [General Information](#general-information)
    - [**What is the helm chart doing?**](#what-is-the-helm-chart-doing)
- [Getting Started](#getting-started)
  - [**Prerequisites**](#prerequisites)
  - [**Installation**](#installation)
  - [**Uninstalling**](#uninstalling)
- [Upgrading](#upgrading)
  - [**Upgrading to 1.1.0**](#upgrading-to-110)
  - [**When the MongoDB pod does not start**](#when-the-mongodb-pod-does-not-start)
  - [**Tools that render the chart without the cluster**](#tools-that-render-the-chart-without-the-cluster)
  - [**Rolling back**](#rolling-back)
  - [**The move to OPC Router 5.7**](#the-move-to-opc-router-57)
- [Configuration](#configuration)
  - [**Parameters**](#parameters)
  - [**Requirements of the OPC Router on Kubernetes**](#requirements-of-the-opc-router-on-kubernetes)
  - [**Storage**](#storage)
  - [**Updates and downtime**](#updates-and-downtime)
  - [**Security**](#security)
  - [**WARNING: MongoDB root password and replica key set**](#warning-mongodb-root-password-and-replica-key-set)
  - [**Image versions**](#image-versions)
  - [**Using the `opcrouter/runtime` image**](#using-the-opcrouterruntime-image)
  - [**Managed clusters with admission policies**](#managed-clusters-with-admission-policies)
  - [**Using Ingress or reverse proxies**](#using-ingress-or-reverse-proxies)
  - [**Extra ports, environment variables, volumes and init containers**](#extra-ports-environment-variables-volumes-and-init-containers)
  - [**High availability**](#high-availability)
  - [**Loading a project from a git repository**](#loading-a-project-from-a-git-repository)
  - [**Adding extra environment variables**](#adding-extra-environment-variables)

## General Information

### **What is the helm chart doing?**
- It deploys the OPC Router onto a Kubernetes cluster, as a Deployment with one pod.
- By default it runs the `opcrouter/service` image and deploys a MongoDB next to it (the Bitnami
  MongoDB chart with MongoDB 4.4.15) as the router's database.
- Alternatively it runs the `opcrouter/runtime` image, which carries its own database.
- The router keeps its data on two persistent volumes, see [Storage](#storage).
- Optionally it adds an Ingress, and loads a project from a git repository and updates it
  automatically.

# Getting Started

## **Prerequisites**
- Kubernetes 1.25 or later. The chart is validated against the API schemas of Kubernetes 1.25,
  1.30 and 1.34.
- Helm 3. `--reset-then-reuse-values` (see [Upgrading](#upgrading)) needs Helm 3.14 or later.
- A default StorageClass, or `claims.inray.storageClassName` and `claims.log.storageClassName`.
- What the router itself needs from the cluster:
  [Requirements of the OPC Router on Kubernetes](#requirements-of-the-opc-router-on-kubernetes).

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
This command installs the OPC Router with standard settings: the `opcrouter/service` image with a
separate MongoDB. Neither the web management nor the MongoDB asks for a login, which is not
recommended beyond a first test, see [Security](#security). Accepting the
[End User License Agreement](https://www.opc-router.com/terms-of-use-and-eula/) by setting
`I_do_accept_the_EULA` to true is required for the OPC Router to run.

To deploy this chart with password authentication for the web management and for the mongodb use this command:
```shell
helm install my-opcrouter opc-router/opc-router \
  --set webManagement.auth.disable=false \
  --set webManagement.auth.initialUser.name=<Your desired initial web management user name>\
  --set webManagement.auth.initialUser.password=<Your desired initial web management user password>\
  --set mongodb.auth.enabled=true \
  --set mongodb.auth.rootPassword=<Your desired mongodb root password> \
  --set mongodb.auth.replicaSetKey=<Your desired mongodb replicaset key> \
  --set I_do_accept_the_EULA=true
```
Keep in mind that the root password and replicaset key can't be changed once set. When leaving the password and/or replicaset key empty when auth is enabled, the chart will autogenerate the missing secret.
MongoDB reads the replica set key as a key file: it needs at least 6 characters, and only letters,
digits, `+`, `/` and `=`. Any other character, a `-` for example, keeps MongoDB from starting.

## **Uninstalling**
The chart with the name `my-opcrouter` can simply be uninstalled by executing:
```shell
helm uninstall my-opcrouter
```
The router's two volume claims are deleted with the release, unless `claims.inray.keepAfterUninstall`
or `claims.log.keepAfterUninstall` is true. The volumes of the bundled MongoDB are not deleted.
When reinstalling the chart under the same name you will have to use the previous mongodb root
password and replica set key, or delete that volume beforehand.

# Upgrading

## **Upgrading to 1.1.0**

Chart 1.1.0 keeps what an existing installation relies on: the names of its volumes, its pod selector
and its database. It changes the following:
- **The default image is OPC Router 5.7** (before: 5.3). A release without an `image.tag` of its own
  moves to 5.7 with this upgrade; read [The move to OPC Router 5.7](#the-move-to-opc-router-57) first.
- The bundled MongoDB runs `bitnamilegacy/mongodb:4.4.15`. Bitnami has removed its versioned images
  from `docker.io/bitnami`, so earlier chart versions can no longer start a new or rescheduled MongoDB
  pod. MongoDB 4.4.15 opens the data of the 4.4.11 image the earlier versions used.
- An existing release keeps its pod selector. Versions up to 1.0.4 put the chart version into it, so
  every upgrade between them failed with `spec.selector: Invalid value … field is immutable`.
- The router pod is replaced with the strategy `Recreate` in every mode (before: only Kubernetes'
  default `RollingUpdate`). A rolling update starts the new pod next to the old one; on a cluster with
  several nodes it can stall for good on the router's `ReadWriteOnce` volumes, and with the embedded
  database the new pod cannot start at all. See [Updates and downtime](#updates-and-downtime). A
  release installed with Helm 4 is switched by one command first, see below.
- The router container gets `S6_BEHAVIOUR_IF_STAGE2_FAILS=2`: a container whose startup fails exits,
  and Kubernetes restarts it, instead of running on without answering.
- The router connects to the bundled MongoDB directly (`directConnection=true` in the connection
  string). The router can set up the MongoDB replica set itself before the MongoDB chart does, and the
  set's member then carries a host name that resolves only inside the MongoDB pod. OPC Router 5.3
  connects anyway; 5.7 follows that name and its web management never starts.
- With the embedded database an init container creates the database's log folder on the log volume;
  a new, empty log volume next to an existing database no longer stops every start. It runs with the
  router's security context and, unless `helperResources` is set, the router's resources, so a policy
  that admitted the router admits it too.
- The project auto-update's service account gets only the permissions it needs, and only then; the
  router pod mounts no API token otherwise.
- The helper images of the project clone and auto-update are pinned: `alpine/git:v2.47.2` and
  `registry.k8s.io/kubectl:v1.33.0` (before: `alpine/git:latest`, `bitnami/kubectl:latest`). A cluster
  that pulls through a mirror or cannot reach `registry.k8s.io` needs them there, or keeps the old ones
  with `project.gitImage` and `project.autoUpdate.kubectlImage`.
- **A project from a git repository is imported over the existing configuration** (before: the
  configuration was deleted first). What the project contains replaces what is there; what was deleted
  from the project stays in the router until it is deleted there. The old way is
  `project.importMode=clear`, which the chart refuses with OPC Router 5.5 from 5.5.6007 on, 5.6 and 5.7:
  their import stops at that step (a known defect). See
  [Loading a project from a git repository](#loading-a-project-from-a-git-repository).
- `helm test` asks the runtime's readiness route and fails while the runtime is not ready.
- A new installation gets volume sizes that fit how the router runs; an existing claim keeps its size.
- New, all off by default: extra ports, environment variables, volumes and init containers,
  resources for every container and a rotation of the embedded database's log.

The upgrade replaces the router pod once, because its pod template changes. With the bundled MongoDB,
a MongoDB pod that still runs another image restarts once on the new one (about 40 seconds on our test
system).

Upgrade with the new defaults and the values you set yourself:
```shell
helm repo update
helm upgrade my-opcrouter opc-router/opc-router --version 1.1.0 --reset-then-reuse-values
```
Instead of `--reset-then-reuse-values` you can pass your complete values file with `-f`. Plain
`--reuse-values` keeps the defaults of your old chart version, among them the MongoDB image that no
longer exists (and the moving helper image tags), and still reports success; with it, add the new
image explicitly:
```shell
helm upgrade my-opcrouter opc-router/opc-router --version 1.1.0 --reuse-values \
  --set mongodb.image.registry=docker.io \
  --set mongodb.image.repository=bitnamilegacy/mongodb \
  --set mongodb.image.tag=4.4.15
```
**With MongoDB authentication and generated passwords** (`mongodb.auth.enabled=true` without
`rootPassword` and `replicaSetKey`), the MongoDB chart refuses every upgrade with `PASSWORDS ERROR: You
must provide your current passwords` until you pass the current values. Read them from the release's
Secret and add them to the upgrade; under this chart the keys are `mongodb.auth.*`, not the `auth.*`
the message names:
```shell
export MONGODB_ROOT_PASSWORD=$(kubectl get secret my-opcrouter-mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d)
export MONGODB_REPLICA_SET_KEY=$(kubectl get secret my-opcrouter-mongodb -o jsonpath="{.data.mongodb-replica-set-key}" | base64 -d)
helm upgrade my-opcrouter opc-router/opc-router --version 1.1.0 --reset-then-reuse-values \
  --set mongodb.auth.rootPassword=$MONGODB_ROOT_PASSWORD \
  --set mongodb.auth.replicaSetKey=$MONGODB_REPLICA_SET_KEY
```

**A release installed with Helm 4** was applied server-side, and because chart versions up to 1.0.4
set no update strategy, Kubernetes filled in a rolling update when it created the router's
Deployment. A server-side apply cannot remove those settings, so 1.1.0 cannot switch the Deployment
to `Recreate` (see [Updates and downtime](#updates-and-downtime)) on its own. The chart stops such an
upgrade before it changes anything, with a message that begins `the Deployment … still has the
rolling update settings Kubernetes gave it at installation`. Switch the Deployment once with the
command the message prints, which does not restart the router, and repeat the upgrade:
```shell
kubectl patch deployment my-opcrouter-opc-router --type merge \
  -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
```
Releases installed with Helm 3 need no such step, also when Helm 4 upgrades them.

To preview an upgrade, use `--dry-run=server`: the chart reads the existing Deployment and volume
claims from the cluster, which a client-side dry run cannot.

Do not use `--atomic` (Helm 3) or `--rollback-on-failure` (Helm 4) for this upgrade. When it does not
finish in time, for example because a stuck MongoDB pod has to be deleted by hand, Helm rolls back to
your old chart version, and that replaces a running MongoDB pod with the image that no longer exists
(see [Rolling back](#rolling-back)).

Releases installed with chart 1.0.0 or 1.0.1 run OPC Router 5.1 or 5.2, unless they set `image.tag`.
The upgrade to 1.1.0 moves them to 5.7 as well; set `image.tag` to stay on your version.

## **When the MongoDB pod does not start**

If the MongoDB pod of a release stays in `ErrImagePull` or `ImagePullBackOff` on
`bitnami/mongodb:4.4.11-debian-10-r12`, the new image alone does not replace it: Kubernetes does not
replace a StatefulSet pod that never became ready. After the upgrade, delete it once:
```shell
kubectl delete pod my-opcrouter-mongodb-0
```
To repair an installation without changing its chart version, give the chart version of its last
**deployed** revision and the image, then delete the pod as above. `helm history my-opcrouter` shows
it; a failed upgrade to 1.0.4 is listed as 1.0.4 although it never deployed, and that version would
fail on the selector again.
```shell
helm upgrade my-opcrouter opc-router/opc-router --version <deployed version> --reuse-values \
  --set mongodb.image.registry=docker.io \
  --set mongodb.image.repository=bitnamilegacy/mongodb \
  --set mongodb.image.tag=4.4.15
```
The image values belong under `mongodb:`. A values file with a top-level `mongo:` key upgrades without
an error and changes nothing.

## **Tools that render the chart without the cluster**

Tools that render the chart with `helm template` instead of installing it, such as Argo CD, give it no
access to the cluster. The chart then cannot read what it keeps for an existing release:
- **The pod selector.** For a release installed with chart 1.0.4 or earlier, the rendered selector
  differs. Kubernetes refuses that change on the Deployment, and applying it to the Service keeps the
  Service's old labels next to the new ones, so it selects no pod. Delete both once and let the tool
  create them again (`kubectl delete deployment,service my-opcrouter-opc-router`); the volumes stay,
  the router restarts.
- **The size of existing volume claims.** Set `claims.inray.capacity` and `claims.log.capacity` to the
  sizes of your claims (`kubectl get pvc`); the defaults of chart 1.0.4 and earlier were `100M` and
  `1Gi`. Otherwise the tool asks Kubernetes to resize them.

## **Rolling back**

`helm rollback` to 1.0.4 or earlier restores that version's MongoDB image, which no longer exists:
Kubernetes replaces the running MongoDB pod with one that cannot start, and the router loses its
database. If you have to go back, repair it as in
[When the MongoDB pod does not start](#when-the-mongodb-pod-does-not-start) with `--version <that version>`.

## **The move to OPC Router 5.7**

Chart 1.1.0 installs OPC Router 5.7 by default, so a release without an `image.tag` of its own moves
from 5.3 to 5.7 with the upgrade to 1.1.0. OPC Router 5.7 runs on the bundled MongoDB 4.4.15; it
supports MongoDB from 4.2 on and recommends 6.0 or later, which a later chart version will provide.
Before you upgrade:
- **Back up first.** Export the project. With the embedded database, the first start of 5.7 migrates
  the database to MongoDB 8, and the 5.3 image cannot open it afterwards.
- **Project import:** a project from a git repository is imported with `overwrite` now. Do not set
  `project.importMode=clear`: it stops the web management of OPC Router 5.7 from starting (a known
  defect), and the chart refuses it. See
  [Loading a project from a git repository](#loading-a-project-from-a-git-repository).
- **If you set `updateStrategy` to `RollingUpdate`, remove it for this upgrade**, so that 5.3 and 5.7 do
  not run side by side on one database; the chart's default `Recreate` avoids that.
- Pin the exact version, see [Image versions](#image-versions). To stay on 5.3, set `image.tag` to
  `5.3` or an exact 5.3 build.

For example with these lines in your values file `my-values.yaml`:
```yaml
image:
  tag: "5.7.5000.16"
```
```shell
helm upgrade my-opcrouter opc-router/opc-router --version 1.1.0 --reset-then-reuse-values -f my-values.yaml
```
# Configuration

## **Parameters**

### **Global parameters**

These are read by the bundled MongoDB chart only.

| Name                       | Description                                                                                                            | Value |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----- |
| `global.imageRegistry`     | Registry of the bundled MongoDB's image, for example a mirror                                                          | `""`  |
| `global.imagePullSecrets`  | Registry secret names of the bundled MongoDB's image, as an array                                                      | `[]`  |
| `global.storageClass`      | StorageClass of the bundled MongoDB's volume                                                                           | `""`  |
| `global.namespaceOverride` | Override the namespace for resource deployed by the chart, but can itself be overridden by the local namespaceOverride | `""`  |

### **Common parameters**

| Name                    | Description                                                                                | Value  |
| ----------------------- | ------------------------------------------------------------------------------------------ | ------ |
| `nameOverride`          | String to partially override opc-router.fullname template (will maintain the release name) | `""`   |
| `fullnameOverride`      | String to fully override opc-router.fullname template                                      | `""`   |
| `I_do_accept_the_EULA`  | If this is false the OPC Router container won't be able to run.                            | `false` |
| `containerHistoryLimit` | The size of the history of deployments kept for potential rollbacks.                       | `10`   |

### **OPC Router parameters**

| Name                              | Description                                                                                                         | Default value       |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `image.repository`                | OPC Router image: `opcrouter/service` (with `mongodb.deploy=true`) or `opcrouter/runtime` (embedded database). May carry a registry. | `opcrouter/service` |
| `image.tag`                       | OPC Router image tag; empty means the chart's app version. See [Image versions](#image-versions).                   | `""` (`5.7`)        |
| `image.pullPolicy`                | OPC Router image pull policy.                                                                                       | `IfNotPresent`      |
| `imagePullSecrets`                | Registry secrets of the router pod.                                                                                 | `[]`                |
| `podAnnotations`                  | Annotations of the router pod.                                                                                      | `{}`                |
| `podSecurityContext`              | Security context of the router pod.                                                                                 | `{}`                |
| `securityContext`                 | Security context of the router container and the log rotation, see [Security](#security).                          | `{}`                |
| `resources`                       | Resource requests and limits of the router container.                                                               | `{}`                |
| `helperResources`                 | Resource requests and limits of the helper containers (project clone and auto-update, log folder, log rotation).    | `{}`                |
| `nodeSelector`                    | Node selector of the router pod.                                                                                    | `{}`                |
| `tolerations`                     | Tolerations of the router pod.                                                                                      | `[]`                |
| `affinity`                        | Affinity of the router pod.                                                                                         | `{}`                |
| `updateStrategy`                  | How the router pod is replaced; empty: `Recreate`. See [Updates and downtime](#updates-and-downtime). | `{}` |
| `envVars`                         | Environment variables of the router container as `Name: "Value"` entries.                                         | `[]`                |
| `extraEnv`                        | Further environment variables as Kubernetes EnvVar entries, `valueFrom` included.                                  | `[]`                |
| `extraVolumes`                    | Further volumes of the router pod.                                                                                  | `[]`                |
| `extraVolumeMounts`               | Further volume mounts of the router container.                                                                      | `[]`                |
| `extraInitContainers`             | Further init containers, run after the chart's own.                                                                 | `[]`                |
| `prepareLogFolder`                | With the embedded database, create its log folder before the router starts.                                        | `true`              |
| `mongodbLogRotation.enabled`      | Rotate the embedded database's log by size, see [Storage](#storage).                                               | `false`             |
| `mongodbLogRotation.maxSizeMB`    | Size at which the log is rotated.                                                                                   | `200`               |
| `mongodbLogRotation.keepFiles`    | Number of rotated log files kept.                                                                                   | `4`                 |
| `mongodbLogRotation.checkIntervalSeconds` | How often the log size is checked.                                                                          | `600`               |
| `serviceAccount.create`           | Specifies whether a service account should be created.                                                              | `true`              |
| `serviceAccount.annotations`      | Annotations to add to the service account.                                                                          | `{}`                |
| `serviceAccount.name`             | Name of the service account to use. If not set and create is true, it is generated using the fullname.              | `""`                |
| `tests.image.repository`          | Image of the `helm test` pod.                                                                                       | `busybox`           |
| `tests.image.tag`                 | Tag of that image.                                                                                                  | `1.37`              |
| `tests.image.pullPolicy`          | Pull policy of that image.                                                                                          | `IfNotPresent`      |
| `tests.resources`                 | Resource requests and limits of the `helm test` pod.                                                                | `{}`                |

### **Web management parameters**

| Name                                      | Description                                                                                             | Default value |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------- |
| `webManagement.auth.disable`              | If false, the web management will require authentication to be accessed.                               | `true`        |
| `webManagement.auth.initialUser.name`     | The username of the initial user. If left empty, there will be no initial user.                         | `""`          |
| `webManagement.auth.initialUser.password` | The password of the initial user. If left empty, there will be no initial user.                         | `""`          |
| `webManagement.https.disable`             | If false, the web management will use https. This requires a TLS key and certificate to be set.         | `true`        |
| `webManagement.https.cert`                | The tls certificate used for https. Is overwritten by existingTlsSecret.                                | `""`          |
| `webManagement.https.key`                 | The tls key corresponding to the certificate used for https. Is overwritten by existingTlsSecret.       | `""`          |
| `webManagement.https.existingTlsSecret`   | An existing kubernetes.io/tls secret. Will overwrite cert and key.                                      | `""`          |

### **Service and Ingress parameters**

| Name                               | Description                                                                                           | Default value |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------- |
| `service.enabled`                  | If false, the application won't be reachable from outside the cluster.                                | `true`        |
| `service.type`                     | Type of the service. Possible values: ClusterIP, NodePort, LoadBalancer.                              | `ClusterIP`   |
| `service.port`                     | Port of the web management on the service.                                                            | `8443`        |
| `service.nodePort`                 | External port. When NodePort, this port will allow external access to the service.                    | `""`          |
| `service.externalIPs`              | External IPs. Reachable under these IPs, when traffic ingresses into cluster with IPs as destination. | `[]`          |
| `service.loadBalancerIP`           | LoadBalancer IP. Used by some cloud providers to add external load balancers.                         | `""`          |
| `service.annotations`              | Annotations of the service, for example for an internal load balancer.                                | `{}`          |
| `service.extraPorts`               | Further ports on the router container and the service, see [Extra ports](#extra-ports-environment-variables-volumes-and-init-containers). | `[]` |
| `ingress.enabled`                  | Create an Ingress for the web management.                                                             | `false`       |
| `ingress.className`                | Ingress class.                                                                                        | `""`          |
| `ingress.annotations`              | Annotations of the Ingress.                                                                           | `{}`          |
| `ingress.hosts`                    | Hosts and paths of the Ingress.                                                                       | `chart-example.local`, `/` |
| `ingress.tls`                      | TLS settings of the Ingress.                                                                          | `[]`          |

### **Volume parameters**

The same keys exist under `claims.inray` (`/data`) and `claims.log` (`/var/log/opcrouter`).

| Name                                         | Description                                                                                  | Default value |
| -------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------- |
| `claims.*.capacity`                          | Requested size. Empty: an existing claim keeps its size, a new one gets the default in [Storage](#storage). | `""` |
| `claims.*.storageClassName`                  | StorageClass of the claim; empty uses the cluster's default.                                 | `""`          |
| `claims.*.keepAfterUninstall`                | Keep the claim when the release is uninstalled.                                              | `false`       |
| `claims.*.storageVolume.createVolume`        | Create a PersistentVolume for the claim with the settings below.                             | `false`       |
| `claims.*.storageVolume.reclaimPolicy`       | Reclaim policy of that volume.                                                               | `Retain`      |
| `claims.*.storageVolume.volumeType`          | Volume type of that volume.                                                                  | `local`       |
| `claims.*.storageVolume.volumeTypeOptions`   | Settings of the volume type.                                                                 | path          |
| `claims.*.storageVolume.mountOptions`        | Mount options of that volume.                                                                | `[]`          |
| `claims.*.storageVolume.nodeAffinity`        | Node affinity of that volume; required with the volume type `local`, which lives on one node. | `{}`          |

### **Bundled MongoDB parameters**

| Name                          | Description                                                                                     | Default value           |
| ----------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------- |
| `mongodb.deploy`              | If false, no MongoDB is deployed. Set it to false with the `opcrouter/runtime` image.          | `true`                  |
| `mongodb.replicaCount`        | Number of MongoDB pods. Must be 1: the router supports only a single-member replica set.       | `1`                     |
| `mongodb.image.registry`      | Registry of the MongoDB image.                                                                  | `docker.io`             |
| `mongodb.image.repository`    | Repository of the MongoDB image.                                                                | `bitnamilegacy/mongodb` |
| `mongodb.image.tag`           | Tag of the MongoDB image.                                                                       | `4.4.15`                |
| `mongodb.resources`           | Resource requests and limits of the MongoDB container.                                          | `{}`                    |
| `mongodb.auth.enabled`        | If false, the mongodb won't require any authentication to access.                               | `false`                 |
| `mongodb.auth.existingSecret` | Existing secret with mongodb credentials (keys: mongodb-root-password, mongodb-replica-set-key). | `""`                    |
| `mongodb.auth.rootPassword`   | Root password for the mongodb. Will override autogenerated or existing one in secret.           | `""`                    |
| `mongodb.auth.replicaSetKey`  | Replica set key for the mongodb. Will override autogenerated or existing one in secret.         | `""`                    |

Every other setting of the bundled Bitnami MongoDB chart, version 10.31.5 (in this repository under
`charts/opc-router/charts/`), can be given under `mongodb:` as well. Its optional containers use
Bitnami images whose versioned tags no longer exist either: for the metrics exporter set
`mongodb.metrics.image.repository=bitnamilegacy/mongodb-exporter` and `mongodb.metrics.image.tag=0.11.2`;
the image of the volume permissions container, `bitnami/bitnami-shell`, has no replacement there.

### **Project parameters**

| Name                                       | Description                                                                                          | Default value             |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------- | ------------------------- |
| `project.projectRepo`                      | URL to the git repository of an OPC Router project. Optional. Empty means no project gets loaded.    | `""`                      |
| `project.projectPath`                      | Path to the project .rpe file in the repository. Don't begin with '/'. Optional.                     | `""`                      |
| `project.configPath`                       | Path to a projects configuration file. Optional. Empty means no configuration file gets loaded.      | `""`                      |
| `project.importMode`                       | `overwrite` or `clear`, see [Loading a project](#loading-a-project-from-a-git-repository).           | `overwrite`               |
| `project.gitImage.*`                       | `repository`, `tag`, `pullPolicy` of the image that clones the project.                              | `alpine/git`, `v2.47.2`   |
| `project.autoUpdate.disable`               | If false, the project is updated when it changes in the repository. Experimental.                    | `true`                    |
| `project.autoUpdate.interval`              | Interval in seconds the repository is fetched.                                                       | `300`                     |
| `project.autoUpdate.kubectlImage.*`        | `repository`, `tag`, `pullPolicy` of the kubectl image; its entrypoint must be `kubectl`.             | `registry.k8s.io/kubectl`, `v1.33.0` |
| `project.auth.ssh_secret`                  | An existing secret containing the ssh key under the key `ssh-privatekey`. Optional.                  | `""`                      |
| `project.auth.ssh_key`                     | SSH private key for accessing the git repository. Overwritten by ssh_secret, Optional.               | `""`                      |

## **Requirements of the OPC Router on Kubernetes**

Without these the router does not run, or does not run reliably:
- **Root start, capabilities, writable root filesystem.** The image starts as root and switches to its
  own service users. It needs user ID 0, the capabilities `CHOWN`, `SETUID`, `SETGID`, `FOWNER` and
  `DAC_OVERRIDE`, and a writable root filesystem. On OpenShift the default security context constraint
  does not allow this; the pod needs `anyuid` or an equivalent (not tested on OpenShift).
- **A persistent volume for `/data`.** It holds the configuration, the license identity and, with the
  `opcrouter/runtime` image, the database. A new or empty volume is a new system for licensing. Never
  copy the volume into a second running instance: both would carry the same license identity.
- **`/var/log/opcrouter` persistent.** An empty volume there stops every start once a database exists
  (the chart's init container covers this for the embedded database's log folder).
- **One router pod per data volume.** The router does not scale horizontally, see
  [High availability](#high-availability).
- **Outbound access to the license server.** Without a TPM, the license is synchronised online with
  `https://license.opc-router.com`, at startup and at least every 72 hours. TPM-based licensing does
  not fit Kubernetes: the identity also depends on the host name and the node's hardware.
- **An external MongoDB is a single-member replica set.** Name the one host and the set in the
  connection string (`mongodb://<host>:27017/?replicaSet=<name>`). Several hosts stop the router from
  starting, and losing a member of a larger set stalls it.
- **The web port with WebSockets.** 8080, or 8443 with HTTPS, is the only port that always has to be
  reachable; an Ingress or a proxy must pass WebSockets through.
- **Memory for the `opcrouter/runtime` image:** a limit of at least 3 to 4 GiB. Its database sizes its
  cache from the limit and leaves 2 GB to the router.

## **Storage**

| Claim | Mounted at | Holds | Size of a new installation |
| ----- | ---------- | ----- | -------------------------- |
| `inray-<release>-opc-router` (`claims.inray`) | `/data` | configuration, license identity; with the embedded database also the database | `1Gi` with the bundled MongoDB, `10Gi` with the embedded database |
| `log-<release>-opc-router` (`claims.log`) | `/var/log/opcrouter` | the router's logs (runtime and web management, up to 2 x 1 GB each); with the embedded database also its log | `4Gi` with the bundled MongoDB, `6Gi` with the embedded database |

An existing claim keeps its size: a bound claim cannot shrink, and growing it needs a StorageClass
that allows volume expansion. To grow one, set `claims.*.capacity` to the new size. To see what the
router uses:
```shell
kubectl exec deploy/my-opcrouter-opc-router -c opc-router -- sh -c 'du -sch /data/* /var/log/opcrouter/*'
```
The embedded database writes its own log, `/var/log/opcrouter/mongodb/mongod.log`, and the image
does not rotate it: on a long-running installation it fills the log volume, and the database stops.
`mongodbLogRotation.enabled=true` rotates it by size and keeps a few rotated files, at most about
`(keepFiles + 1) x maxSizeMB`.

The embedded database is a MongoDB and needs a file system MongoDB supports for its data files; put
`/data` on a block-storage volume rather than a network file share (see MongoDB's production notes).

On a cluster with several nodes, the volumes must either follow the pod to another node or keep the
pod on their node. Storage that is local to a node but carries no node affinity (some test
provisioners, for example minikube's default `standard` class) hands a pod that moves to another node
an empty `/data`: a new system for licensing, and with the embedded database an empty database.

## **Updates and downtime**

When the router is upgraded or its settings change, Kubernetes replaces its pod. The chart uses
`Recreate` in every mode: on a rollout the old pod stops before the new one starts. The router
mounts its two volumes as `ReadWriteOnce`, and a rolling update would start the new pod first:
- **On a cluster with several nodes**, a volume that is attached to one node at a time, such as a
  cloud disk (Azure Disk, EBS), cannot follow the new pod to another node while the old pod holds
  it. The new pod waits, the old pod is not removed before the new one is ready, and the rollout
  stalls for good.
- **With the embedded database** the new pod cannot open the database the old one still uses.

A pod that is deleted or evicted is replaced at once, `Recreate` or not; the new one then waits or
restarts until the old one has released its volumes and database.

A rolling update is safe only with a separate MongoDB, and only on a single node, with volumes
pinned to one node (such as local volumes, for example the `local-path` storage of k3s; measured on
three nodes: the new pod returned to that node, no stall), or with volumes that are not attached to
nodes. There it shortens the interruption (in our measurement on one node, requests failed for about
6 seconds), at the price of two routers running the same project for a short time:
```yaml
updateStrategy:
  type: RollingUpdate
```
With volumes pinned to one node, the router cannot start anywhere else while that node is
unavailable; its node is a single point of failure.

With `Recreate` the router is unavailable from the stop of the old pod until the new one is ready; on
our test systems the router answered 9 to 36 seconds after its start, the longest with the database
migration of a new version, and longer when its image first has to be pulled. Keep that short by
keeping the image on the nodes (pull policy `IfNotPresent`, an exact image tag, the image pulled ahead
of a planned upgrade). Uninterrupted operation needs the router's redundancy mode, see
[High availability](#high-availability).

## **Security**

- **The web management has no login by default** (`webManagement.auth.disable=true`). Whoever can
  reach the service can change the router's configuration. Set `webManagement.auth.disable=false` and
  an initial user; to keep its password out of the values, leave
  `webManagement.auth.initialUser.password` empty and read it from a Secret:
```yaml
extraEnv:
  - name: INITIAL_PASSWORD
    valueFrom:
      secretKeyRef:
        name: opc-router-initial-user
        key: password
```
- **The bundled MongoDB has no login by default** (`mongodb.auth.enabled=false`); see the warning
  below before you enable it.
- **The service account** gets permissions and an API token only with the project auto-update: a Role
  that may list and delete the pods of the namespace, so a new project version restarts the router; the
  restart itself selects only this release's pods. The role is bound to the chart's own account or to
  the one named in `serviceAccount.name`, never to the namespace's `default` account, which other pods
  share. With `serviceAccount.create=false` and no name the auto-update therefore cannot restart the
  router.
- **The security context** that grants only what the router needs:
```yaml
securityContext:
  capabilities:
    drop:
      - ALL
    add:
      - CHOWN
      - SETUID
      - SETGID
      - FOWNER
      - DAC_OVERRIDE
```
Running as another user, dropping these capabilities or `readOnlyRootFilesystem: true` stop the router.

## **WARNING: MongoDB root password and replica key set**

When using the mongodb container, keep in mind that that the root password and replica key set can only be set once, as upon initial declaration they are stored in a persistent volume. This may be an issue when using automatically deploying the chart using ArgoCD or Flux, as automatic redeployments can cause the root password to be regenerated when not having set static values for them in the values.yaml. This however will only make the database inaccessible to the OPC Router, as it will use the new passwords, though the mongodb still uses the old initial passwords. Thus it is highly recommended to set `mongodb.auth.existingSecret` or `mongodb.auth.rootPassword` and `mongodb.auth.replicaSetKey` when not manually deploying the chart for testing purposes.

## **Image versions**

The default image tag, `5.7`, moves with every maintenance build of OPC Router 5.7, and so does a tag
like `5.3`. Under the pull policy `IfNotPresent` a node keeps the build it pulled first, so after a
reschedule two nodes can run different builds of the same tag. In production pin an exact version,
for example:
```shell
--set image.tag=5.7.5000.16
```
Like the movable tags, the exact tags on Docker Hub are multi-architecture images.

## **Using the `opcrouter/runtime` image**

By default the chart runs the `opcrouter/service` image, which has no database of its own, and deploys
a MongoDB next to it. The `opcrouter/runtime` image carries its own database:
```shell
helm install my-opcrouter opc-router/opc-router \
  --set image.repository=opcrouter/runtime \
  --set mongodb.deploy=false \
  --set I_do_accept_the_EULA=true
```
Always set `mongodb.deploy=false` with it: otherwise the chart deploys the separate MongoDB as well,
and the router uses that one.

The embedded database lives on the data volume, which a new installation therefore creates with 10Gi,
see [Storage](#storage). Give the router container a memory limit of at least 3 to 4 GiB.

## **Managed clusters with admission policies**

Managed clusters often reject pods without resource limits, forbid broad permissions for service
accounts and reach their images through a registry of their own. Every container of the chart takes
resources, and every image can be redirected:
```yaml
image:
  repository: myregistry.example.com/opcrouter/runtime
  tag: "5.7.5000.16"
mongodb:
  deploy: false
serviceAccount:
  create: false
resources:
  requests:
    cpu: 500m
    memory: 4Gi
  limits:
    cpu: "2"
    memory: 4Gi
helperResources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi
tests:
  image:
    repository: myregistry.example.com/library/busybox
  resources:
    limits:
      cpu: 100m
      memory: 64Mi
service:
  type: LoadBalancer
  annotations:
    # an internal load balancer on Azure; other providers use their own annotation
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
  extraPorts:
    - name: opcua
      port: 49420
nodeSelector:
  agentpool: user
claims:
  inray:
    capacity: 10Gi
  log:
    capacity: 6Gi
```
With the bundled MongoDB, give it resources under `mongodb.resources` and redirect its image with
`global.imageRegistry`. With a project from git, `project.gitImage` and
`project.autoUpdate.kubectlImage` name the helper images. `service.loadBalancerIP` is deprecated in
Kubernetes; providers offer an annotation for a fixed address instead.

## **Using Ingress or reverse proxies**

The rerouting of the traffic for to the OPC Router web management may require some extra configuration. Generally, when some form of reverse proxy is being used, the `ASPNETCORE_FORWARDEDHEADERS_ENABLED` environment variable needs to be set to `true`. When `ingress.enabled` is set to `true` this is already automatically done.

In some configurations it is desirable to change the base path for the OPC Router web management. This always requires setting the `WEB_BASE_PATH` environment variable to the new base path for the OPC Router web management to properly function.

For configuring environment variables, refer to [Adding extra environment variables](#adding-extra-environment-variables).

## **Extra ports, environment variables, volumes and init containers**

`service.extraPorts` opens a port on the router container and on the service, for example the OPC UA
server of a project or a plug-in's listener:
```yaml
service:
  extraPorts:
    - name: opcua        # at most 15 lowercase letters, digits and '-'
      port: 49420
      # targetPort: 49420  container port, defaults to port
      # protocol: TCP
      # nodePort: 31420    NodePort and LoadBalancer only
```
The OPC UA server plug-in advertises the pod's host name in its `opc.tcp` endpoints. Clients that keep
the address they dialled work through the service; clients that switch to the advertised address
need that name to resolve.

`extraEnv` takes Kubernetes EnvVar entries, so a value can come from a Secret or a ConfigMap (see
[Security](#security)). `extraVolumes` and `extraVolumeMounts` add volumes to the router container,
for example an `odbc.ini` for the ODBC plug-in:
```yaml
extraVolumes:
  - name: odbc
    configMap:
      name: odbc-ini
extraVolumeMounts:
  - name: odbc
    mountPath: /etc/odbc.ini
    subPath: odbc.ini
```
`extraInitContainers` run after the chart's own init containers.

## **High availability**

The router does not scale horizontally: one pod per data volume, and `replicas` stays 1. Several
MongoDB members are not supported either; `mongodb.replicaCount` must stay 1. High availability is the
router's redundancy mode, two independent instances with a primary and a secondary, which this chart
does not deploy yet.

## **Loading a project from a git repository**
Please refer to [this sample project](https://github.com/OPC-Router/helm-sample-project) on general information of how to deploy a OPC Router project from a git repository onto a kubernetes cluster using this helm chart.

At every start the router imports the project. `project.importMode` decides how:
- `overwrite` (default) imports the project over the existing configuration: what the project contains
  replaces what is there, everything else stays. Something deleted from the project therefore stays in
  the router until it is deleted there. It needs OPC Router 5.1.5001 or later.
- `clear` deletes the configuration first, so the router runs exactly the project. OPC Router 5.5 from
  5.5.6007 on, 5.6 and 5.7 stop at this step and the web management never starts (a known defect).
  The chart refuses `clear` when `image.tag` names one of these versions, before anything is changed;
  with another tag, such as `latest` or one of your own, it warns after the installation.

With `project.autoUpdate.disable=false` a container fetches the repository every
`project.autoUpdate.interval` seconds and restarts the router when the project has changed. At its
start it installs `curl` from the Alpine package repository, so it needs access to it.

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
  --set envVars[1].OtherVariable="42" \
  --set envVars[2].yetAnotherVar="false" \
  --set I_do_accept_the_EULA=true
```
Values from a Secret or a ConfigMap go into `extraEnv`, see
[Extra ports, environment variables, volumes and init containers](#extra-ports-environment-variables-volumes-and-init-containers).
