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