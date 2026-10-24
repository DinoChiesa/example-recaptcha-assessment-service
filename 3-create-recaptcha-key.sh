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

check_shell_variables RECAPTCHA_PROJECT_ID RECAPTCHA_KEY_DISPLAY_NAME RECAPTCHA_KEY_DOMAINS
check_required_commands gcloud

printf "\nThis script creates a score-based reCAPTCHA key for the web.\n"
printf "That is the key type the simplecheck-enterprise page needs, because it\n"
printf "calls grecaptcha.enterprise.execute() rather than rendering a checkbox.\n\n"

existing_key=$(gcloud recaptcha keys list \
  --project "$RECAPTCHA_PROJECT_ID" \
  --filter "displayName=${RECAPTCHA_KEY_DISPLAY_NAME}" \
  --format 'value(name.basename())' | head -1)

if [[ -n "$existing_key" ]]; then
  printf "A key named '%s' already exists.\n" "$RECAPTCHA_KEY_DISPLAY_NAME"
  site_key="$existing_key"
else
  site_key=$(gcloud recaptcha keys create \
    --project "$RECAPTCHA_PROJECT_ID" \
    --display-name "$RECAPTCHA_KEY_DISPLAY_NAME" \
    --web \
    --domains "$RECAPTCHA_KEY_DOMAINS" \
    --integration-type score \
    --format 'value(name.basename())')
fi

if [[ -z "$site_key" ]]; then
  printf "Could not create or find the key.\n"
  exit 1
fi

printf "\nSite key: %s\n\n" "$site_key"
printf "Set it into your environment, before deploying the service:\n"
printf "   export RECAPTCHA_SITE_KEY=%s\n\n" "$site_key"
printf "Also paste it into the 'Enterprise Site Key' field in the web page.\n"
