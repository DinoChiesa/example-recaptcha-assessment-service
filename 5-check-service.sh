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

if [[ $# -gt 1 || ($# -eq 1 && "$1" != "--local") ]]; then
  printf "usage: %s [--local]\n" "$0"
  exit 1
fi

check_required_commands curl

if [[ "$1" == "--local" ]]; then
  url="http://localhost:${LOCAL_PORT}"
else
  check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION
  check_required_commands gcloud
  url=$(service_url)
  if [[ -z "$url" ]]; then
    printf "The service is not deployed.\n"
    exit 1
  fi
fi

printf "\nHealth check: GET %s/\n" "$url"
curl -s "$url/"
printf "\n"

# A real token can only come from a browser. A bogus token proves the service
# can reach the reCAPTCHA API with its credentials; expect valid=false.
printf "\nAssessment with a bogus token: POST %s/assess\n" "$url"
curl -s -X POST "$url/assess" \
  -H 'Content-Type: application/json' \
  -d '{"recaptcha_token":"not-a-real-token"}'
printf "\n"
