#!/usr/bin/env bash
# Lints the chart with every values file under .github/ci/values, renders it for several
# Kubernetes versions and validates the rendered manifests against the Kubernetes schemas.
# Exits non-zero if any lint, render or validation fails.
set -euo pipefail

chart="${CHART:-charts/opc-router}"
values_dir="${VALUES_DIR:-.github/ci/values}"
kube_versions="${KUBE_VERSIONS:-1.25.0 1.30.0 1.34.0}"
status=0

shopt -s nullglob
values_files=("${values_dir}"/*.yaml)
if [ "${#values_files[@]}" -eq 0 ]; then
  echo "No values files found in ${values_dir}" >&2
  exit 1
fi

for values in "${values_files[@]}"; do
  echo "::group::${values}"
  if ! helm lint "${chart}" --strict -f "${values}"; then
    echo "::error::helm lint failed for ${values}"
    status=1
  fi
  for kube_version in ${kube_versions}; do
    if ! helm template ci "${chart}" -f "${values}" --kube-version "${kube_version}" \
      | kubeconform -strict -summary -kubernetes-version "${kube_version}"; then
      echo "::error::render or schema validation failed for ${values} on Kubernetes ${kube_version}"
      status=1
    fi
  done
  echo "::endgroup::"
done

exit "${status}"
