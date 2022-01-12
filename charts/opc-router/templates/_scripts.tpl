{{/*
Commands to setup ssh authentification for the project repo
*/}} 
{{- define "project.ssh" }}
  {{- if (or $.Values.project.auth.ssh_key $.Values.project.auth.ssh_secret) }}
  cd ~;
  mkdir .ssh;
  cd .ssh;
  ssh -o StrictHostKeyChecking=no {{ regexFind "[@\\/][^:\\/]*[\\/:]" $.Values.project.projectRepo | trimPrefix "\\/" | trimPrefix "@" | trimSuffix "\\/" | trimSuffix ":"}};
  echo -e $PROJECT_SSH_KEY > id;
  chmod 400 id;
  eval `ssh-agent`;
  ssh-add id;
  {{- end }}
{{- end }}

{{/*
Commands to clone the project repo
*/}} 
{{- define "project.clone" }}
  {{- include "project.ssh" $}}  
  rm -rf /data/project;
  mkdir -p /data/project;
  git clone {{ .Values.project.projectRepo }} /data/project;
  echo Done;
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
      sleep 60;
      {{- if (or $.Values.project.auth.ssh_key $.Values.project.auth.ssh_secret) }}
      eval \`ssh-agent\`;
      ssh-add ~/.ssh/id;
      {{- end }}
      git fetch;
      if [ \$(git rev-parse HEAD) != \$(git rev-parse @{u}) ]; then
        git pull;
        curl -XDELETE http://localhost:8001/api/v1/namespaces/{{ .Release.Namespace }}/pods?labelSelector=app.kubernetes.io/name={{ .Chart.Name }};
      fi
    done
  EOF

  chmod 777 ~/gitops.sh;
  ~/gitops.sh;
 {{- end }}