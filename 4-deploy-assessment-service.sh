#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

# Copyright © 2026 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source ./lib/utils.sh

usage() {
  printf "usage: %s [--local]\n" "$0"
  printf "  (no option)  deploy the service to Cloud Run\n"
  printf "  --local      run the service on this machine, on port \$LOCAL_PORT (default 5150)\n"
}

run_locally() {
  check_shell_variables RECAPTCHA_PROJECT_ID RECAPTCHA_SITE_KEY EXPECTED_ACTION ALLOWED_ORIGINS
  check_required_commands gcloud node pnpm

  # Locally, the service uses your Application Default Credentials rather
  # than the runtime service account.
  if ! gcloud auth application-default print-access-token &>/dev/null; then
    printf "No Application Default Credentials. Run this, then re-run this script:\n"
    printf "  gcloud auth application-default login\n"
    exit 1
  fi

  cd app || exit 1
  [[ -d node_modules ]] || pnpm install --frozen-lockfile

  printf "\nRunning the service locally. Endpoint URL for the web page:\n"
  printf "  http://localhost:%s/assess\n" "$LOCAL_PORT"
  printf "Press Ctrl-C to stop.\n\n"
  PORT="$LOCAL_PORT" exec node server.js
}

deploy_to_cloud_run() {
  check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION \
    RECAPTCHA_PROJECT_ID RECAPTCHA_SITE_KEY EXPECTED_ACTION ALLOWED_ORIGINS RUNTIME_SHORT_SA
  check_required_commands gcloud

  printf "\nThis script deploys or redeploys the Cloud Run service named '%s'\n" "$CLOUDRUN_SERVICE_NAME"
  printf "in the project '%s', from source, using the Dockerfile in the app directory.\n" "$CLOUDRUN_PROJECT_ID"
  printf "The service scales to zero and allows unauthenticated access, because\n"
  printf "browsers call it directly.\n\n"

  # ALLOWED_ORIGINS contains commas, so use '|' as the env-var delimiter.
  # See: gcloud topic escaping
  local env_vars="^|^RECAPTCHA_PROJECT_ID=${RECAPTCHA_PROJECT_ID}"
  env_vars+="|RECAPTCHA_SITE_KEY=${RECAPTCHA_SITE_KEY}"
  env_vars+="|EXPECTED_ACTION=${EXPECTED_ACTION}"
  env_vars+="|ALLOWED_ORIGINS=${ALLOWED_ORIGINS}"

  gcloud run deploy "$CLOUDRUN_SERVICE_NAME" \
    --source ./app \
    --service-account "$(runtime_sa_email)" \
    --set-env-vars "$env_vars" \
    --cpu 1 \
    --memory '256Mi' \
    --concurrency 20 \
    --min-instances 0 \
    --max-instances 2 \
    --no-invoker-iam-check \
    --region "$CLOUDRUN_SERVICE_REGION" \
    --project "$CLOUDRUN_PROJECT_ID" \
    --quiet

  printf "\nEndpoint URL for the web page:\n  %s/assess\n" "$(service_url)"
  printf "\nOk.\n"
}

# ====================================================================

if [[ $# -gt 1 || ($# -eq 1 && "$1" != "--local") ]]; then
  usage
  exit 1
fi

if [[ -z "$RECAPTCHA_SITE_KEY" ]]; then
  printf "RECAPTCHA_SITE_KEY is not set.\n"
  printf "Run ./3-create-recaptcha-key.sh and paste the export command it prints.\n"
  exit 1
fi

if [[ "$1" == "--local" ]]; then
  run_locally
else
  deploy_to_cloud_run
fi
