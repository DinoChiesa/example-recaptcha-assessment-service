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

check_shell_variables CLOUDRUN_PROJECT_ID
check_required_commands gcloud

printf "\nThis script grants roles to the default compute service account, so that\n"
printf "Cloud Build can build and deploy the service from source.\n"

# run.developer: deploy Cloud Run services
# logging.logWriter: write build logs
# artifactregistry.writer: push the built image
# iam.serviceAccountUser: act as the runtime service account during deploy
# storage.admin: read the uploaded source archive
project_number=$(gcloud projects describe "$CLOUDRUN_PROJECT_ID" --format="value(projectNumber)")
sa_email="${project_number}-compute@developer.gserviceaccount.com"

required_roles=("run.developer" "logging.logWriter" "artifactregistry.writer"
  "iam.serviceAccountUser" "storage.admin")

for role in "${required_roles[@]}"; do
  printf "Role %s...\n" "$role"
  gcloud projects add-iam-policy-binding "$CLOUDRUN_PROJECT_ID" \
    --condition=None \
    --member "serviceAccount:${sa_email}" \
    --role "roles/${role}" \
    --quiet >/dev/null
done

printf "\nOk.\n"
