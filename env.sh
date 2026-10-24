#!/bin/bash
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

# Source this file: source ./env.sh

# Variables you must set to something that works for you.
export CLOUDRUN_PROJECT_ID=my-gcp-project

# The reCAPTCHA key must live in the project that creates assessments.
# Normally that is the same project as the Cloud Run service.
export RECAPTCHA_PROJECT_ID="$CLOUDRUN_PROJECT_ID"

# Variables you can change if you like
export CLOUDRUN_SERVICE_REGION=us-west1
export RECAPTCHA_KEY_DOMAINS=dinochiesa.github.io,localhost
export ALLOWED_ORIGINS=https://dinochiesa.github.io,http://localhost:8080
export EXPECTED_ACTION=homepage
export LOCAL_PORT=5150

# It's probably best to just keep these unchanged.
export CLOUDRUN_SERVICE_NAME=recaptcha-assessment
export RUNTIME_SHORT_SA=recaptcha-assessor
export RECAPTCHA_KEY_DISPLAY_NAME=recaptcha-assessment-sample
