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

check_shell_variables RECAPTCHA_PROJECT_ID ASSESSMENT_DAILY_CAP
check_required_commands gcloud

quota_id=CreateAssessmentRequestsPerDayPerProject
service=recaptchaenterprise.googleapis.com

current_cap() {
  gcloud beta quotas info describe "$quota_id" \
    --service "$service" \
    --project "$RECAPTCHA_PROJECT_ID" \
    --format 'value(dimensionsInfos[0].details.value)'
}

printf "\nThis script caps the number of reCAPTCHA assessments the project can\n"
printf "create per day. The /assess endpoint is unauthenticated, so this cap is\n"
printf "what bounds the cost if someone calls it in a loop. Beyond the cap, the\n"
printf "API returns HTTP 429 until the next day.\n\n"

printf "Current daily cap: %s  (-1 means unlimited)\n" "$(current_cap)"

# --allow-missing creates the preference on the first run and updates it after.
# Going from unlimited to a small number counts as a large decrease.
if ! output=$(gcloud beta quotas preferences update cap-assessments-per-day \
  --project "$RECAPTCHA_PROJECT_ID" \
  --service "$service" \
  --quota-id "$quota_id" \
  --preferred-value "$ASSESSMENT_DAILY_CAP" \
  --allow-missing \
  --allow-high-percentage-quota-decrease \
  --quiet 2>&1); then
  printf "%s\n" "$output"
  exit 1
fi

printf "New daily cap:     %s\n" "$(current_cap)"
printf "\nOk.\n"
