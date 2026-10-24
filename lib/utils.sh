#!/bin/bash
# Copyright © 2024-2026 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Port for running the service locally. Defaulted here, so that a shell that
# sourced an older env.sh still works.
: "${LOCAL_PORT:=5150}"

check_shell_variables() {
  local missing_vars=()
  local var_name
  for var_name in "$@"; do
    if [[ -z "${!var_name}" ]]; then
      missing_vars+=("$var_name")
    fi
  done

  if [[ ${#missing_vars[@]} -ne 0 ]]; then
    printf -v joined '%s,' "${missing_vars[@]}"
    printf "You must set these environment variables: %s\n" "${joined%,}"
    exit 1
  fi

  printf "Settings in use:\n"
  for var_name in "$@"; do
    printf "  %s=%s\n" "$var_name" "${!var_name}"
  done
  printf "\n"
}

check_required_commands() {
  local missing=()
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -ne 0 ]]; then
    printf -v joined '%s,' "${missing[@]}"
    printf "\n\nThese commands are missing; they must be available on path: %s\nExiting.\n" "${joined%,}"
    exit 1
  fi
}

runtime_sa_email() {
  printf "%s@%s.iam.gserviceaccount.com" "$RUNTIME_SHORT_SA" "$CLOUDRUN_PROJECT_ID"
}

service_url() {
  gcloud run services describe "$CLOUDRUN_SERVICE_NAME" \
    --region "$CLOUDRUN_SERVICE_REGION" \
    --project "$CLOUDRUN_PROJECT_ID" \
    --format 'value(status.url)'
}
