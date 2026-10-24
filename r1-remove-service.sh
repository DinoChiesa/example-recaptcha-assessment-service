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

check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION \
  RECAPTCHA_PROJECT_ID RUNTIME_SHORT_SA
check_required_commands gcloud

sa_email=$(runtime_sa_email)

printf "\nDeleting the Cloud Run service '%s'...\n" "$CLOUDRUN_SERVICE_NAME"
gcloud run services delete "$CLOUDRUN_SERVICE_NAME" \
  --region "$CLOUDRUN_SERVICE_REGION" \
  --project "$CLOUDRUN_PROJECT_ID" \
  --quiet

printf "\nRemoving the reCAPTCHA role binding for %s...\n" "$sa_email"
gcloud projects remove-iam-policy-binding "$RECAPTCHA_PROJECT_ID" \
  --condition=None \
  --member "serviceAccount:${sa_email}" \
  --role "roles/recaptchaenterprise.agent" \
  --quiet >/dev/null

printf "\nDeleting the service account %s...\n" "$sa_email"
gcloud iam service-accounts delete "$sa_email" --project "$CLOUDRUN_PROJECT_ID" --quiet

printf "\nThe reCAPTCHA key is left in place. To delete it:\n"
printf "  gcloud recaptcha keys delete KEY_ID --project %s\n" "$RECAPTCHA_PROJECT_ID"
printf "\nOk.\n"
