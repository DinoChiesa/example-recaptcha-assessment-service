// Copyright © 2026 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import express from "express";
import cors from "cors";
import { GoogleAuth } from "google-auth-library";

const PORT = process.env.PORT || 8080;
const PROJECT_ID = process.env.RECAPTCHA_PROJECT_ID;
const SITE_KEY = process.env.RECAPTCHA_SITE_KEY;
const EXPECTED_ACTION = process.env.EXPECTED_ACTION || "homepage";
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

if (!PROJECT_ID || !SITE_KEY) {
  console.error("RECAPTCHA_PROJECT_ID and RECAPTCHA_SITE_KEY must be set.");
  process.exit(1);
}

const auth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});

async function createAssessment({ token, userAgent, userIpAddress }) {
  const client = await auth.getClient();
  const response = await client.request({
    url: `https://recaptchaenterprise.googleapis.com/v1/projects/${PROJECT_ID}/assessments`,
    method: "POST",
    data: {
      event: {
        token,
        siteKey: SITE_KEY,
        expectedAction: EXPECTED_ACTION,
        userAgent,
        userIpAddress,
      },
    },
  });
  return response.data;
}

function trimToken(assessment) {
  const token = assessment.event?.token;
  if (!token) return assessment;
  return {
    ...assessment,
    event: { ...assessment.event, token: `${token.slice(0, 7)}...` },
  };
}

function summarize(assessment) {
  const { tokenProperties = {}, riskAnalysis = {} } = assessment;
  return {
    valid: Boolean(tokenProperties.valid),
    invalidReason: tokenProperties.invalidReason,
    action: tokenProperties.action,
    expectedAction: EXPECTED_ACTION,
    actionMatches: tokenProperties.action === EXPECTED_ACTION,
    hostname: tokenProperties.hostname,
    score: riskAnalysis.score,
    reasons: riskAnalysis.reasons,
  };
}

const app = express();
// Cloud Run sits behind a Google front end that sets X-Forwarded-For.
app.set("trust proxy", true);
app.use(cors({ origin: ALLOWED_ORIGINS.length ? ALLOWED_ORIGINS : true }));
app.use(express.json());

app.get("/", (_req, res) => {
  res.json({
    status: "ok",
    service: process.env.K_SERVICE || "local",
    revision: process.env.K_REVISION || "local",
  });
});

app.post("/assess", async (req, res) => {
  const token = req.body?.recaptcha_token;
  if (typeof token !== "string" || !token) {
    return res.status(400).json({ error: "recaptcha_token is required" });
  }
  try {
    const assessment = await createAssessment({
      token,
      userAgent: req.get("user-agent"),
      userIpAddress: req.ip,
    });
    res.json({
      summary: summarize(assessment),
      assessment: trimToken(assessment),
    });
  } catch (e) {
    const status = e.response?.status || 500;
    const detail = e.response?.data?.error || { message: e.message };
    console.error(`assessment failed (${status}):`, JSON.stringify(detail));
    res.status(status).json({ error: "assessment failed", detail });
  }
});

app.listen(PORT, () => {
  console.log(`listening on ${PORT}`);
  console.log(`project=${PROJECT_ID} expectedAction=${EXPECTED_ACTION}`);
  console.log(`allowed origins: ${ALLOWED_ORIGINS.join(", ") || "(any)"}`);
});
