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

check_shell_variables CLOUDRUN_PROJECT_ID RECAPTCHA_PROJECT_ID RUNTIME_SHORT_SA
check_required_commands gcloud

sa_email=$(runtime_sa_email)

printf "\nThis script creates the service account the Cloud Run service runs as,\n"
printf "and grants it permission to create reCAPTCHA assessments.\n\n"

if gcloud iam service-accounts describe "$sa_email" --project "$CLOUDRUN_PROJECT_ID" &>/dev/null; then
  printf "The service account '%s' already exists.\n" "$sa_email"
else
  printf "Creating the service account '%s'...\n" "$sa_email"
  gcloud iam service-accounts create "$RUNTIME_SHORT_SA" --project "$CLOUDRUN_PROJECT_ID" --quiet
  printf "Sleeping a bit, so the new service account propagates...\n"
  sleep 10
fi

printf "\nGranting roles/recaptchaenterprise.agent in %s...\n" "$RECAPTCHA_PROJECT_ID"
gcloud projects add-iam-policy-binding "$RECAPTCHA_PROJECT_ID" \
  --condition=None \
  --member "serviceAccount:${sa_email}" \
  --role "roles/recaptchaenterprise.agent" \
  --quiet >/dev/null

printf "\nOk.\n"
