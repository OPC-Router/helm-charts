{{/*
Commands to setup ssh authentification for the project repo
*/}} 
{{- define "project.ssh" }}
  {{- if (or $.Values.project.auth.ssh_key $.Values.project.auth.ssh_secret) }}
  ssh -o StrictHostKeyChecking=no {{ regexFind "[@\\/][^:\\/]*[\\/:]" $.Values.project.projectRepo | trimPrefix "\\/" | trimPrefix "@" | trimSuffix "\\/" | trimSuffix ":"}};
  cd ~;
  mkdir -p .ssh;
  cd .ssh;
  cp /.ssh/ssh-privatekey key;
  chmod 400 key;
  eval `ssh-agent`;
  ssh-add key;
  {{- end }}
{{- end }}

{{/*
Commands to clone the project repo
*/}} 
{{- define "project.clone" }}
  {{- include "project.ssh" $}}  
  rm -rf /data/project;
  mkdir -p /data/project;
  cd /data/project;
  git clone {{ .Values.project.projectRepo }} .;
  ls;
  echo Done;
{{- end }}

{{/*
Rotation of the embedded database's log by size. The router image runs mongod with
--logRotate reopen: the log is renamed first, then logRotate makes mongod open a new file under the
old name. Until mongod has reopened its log it keeps writing into the renamed file, so the command
is repeated while the log path is missing.
*/}}
{{- define "opc-router.mongodbLogRotation" -}}
{{- $rotation := .Values.mongodbLogRotation | default dict -}}
trap 'exit 0' TERM INT
log=/var/log/opcrouter/mongodb/mongod.log
max=$(( {{ dig "maxSizeMB" 200 $rotation | int }} * 1024 * 1024 ))
keep={{ dig "keepFiles" 4 $rotation | int }}
while true; do
  if [ -f "$log" ] && [ "$(stat -c %s "$log")" -gt "$max" ]; then
    mv "$log" "$log.$(date -u +%Y%m%dT%H%M%SZ)"
  fi
  if [ ! -f "$log" ] && ls "$log".* > /dev/null 2>&1; then
    mongosh --quiet --port 27017 --eval 'db.adminCommand({ logRotate: 1 })' > /dev/null || echo "mongod did not reopen its log, retrying" >&2
  fi
  ls -1t "$log".* 2>/dev/null | tail -n +$((keep + 1)) | xargs -r rm -f
  sleep {{ dig "checkIntervalSeconds" 600 $rotation | int }} &
  wait $!
done
{{- end }}

{{/*
Commands to continuously update the project and restart the pod on new version
*/}}
{{- define "project.gitops" }}
{{- include "project.ssh" $}}
  apk add curl; 
  cat <<EOF > ~/gitops.sh
    cd /data/project;
    while [ true ]; do
      sleep {{ .Values.project.autoUpdate.interval }};
      {{- if (or $.Values.project.auth.ssh_key $.Values.project.auth.ssh_secret) }}
      eval \`ssh-agent\`;
      ssh-add ~/.ssh/key;
      {{- end }}
      git fetch;
      if [ \$(git rev-parse HEAD) != \$(git rev-parse @{u}) ]; then
        git pull;
        curl -XDELETE "http://localhost:8001/api/v1/namespaces/{{ .Release.Namespace }}/pods?labelSelector=app.kubernetes.io/name={{ include "opc-router.name" . }},app.kubernetes.io/instance={{ .Release.Name }}";
      fi
    done
  EOF

  chmod 777 ~/gitops.sh;
  ~/gitops.sh;
 {{- end }}