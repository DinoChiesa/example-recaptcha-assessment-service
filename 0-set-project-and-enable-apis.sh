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

check_shell_variables CLOUDRUN_PROJECT_ID RECAPTCHA_PROJECT_ID
check_required_commands gcloud

printf "\nThis script sets the Google Cloud project for gcloud, and enables the services/APIs\n"
printf "needed for this example.\n"

printf "\nSetting default project...\n"
gcloud config set project "$CLOUDRUN_PROJECT_ID"

printf "\nEnabling APIs in %s...\n" "$CLOUDRUN_PROJECT_ID"
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  recaptchaenterprise.googleapis.com \
  cloudquotas.googleapis.com \
  --project "$CLOUDRUN_PROJECT_ID"

if [[ "$RECAPTCHA_PROJECT_ID" != "$CLOUDRUN_PROJECT_ID" ]]; then
  printf "\nEnabling reCAPTCHA and Cloud Quotas APIs in %s...\n" "$RECAPTCHA_PROJECT_ID"
  gcloud services enable recaptchaenterprise.googleapis.com cloudquotas.googleapis.com \
    --project "$RECAPTCHA_PROJECT_ID"
fi

printf "\nOk.\n"
