# reCAPTCHA Assessment Service

A small Cloud Run service that creates
[reCAPTCHA assessments](https://cloud.google.com/recaptcha/docs/create-assessment-website)
for tokens posted from a browser.

It is the backend for the demo page at
**<https://dinochiesa.github.io/recaptcha/>**. That page generates a reCAPTCHA
token in your browser and posts it to an assessment endpoint that you supply.
This repo lets you run that endpoint yourself, in your own Google Cloud
project, with your own reCAPTCHA key.

## Disclaimer

This example is not an official Google product, nor is it part of an
official Google product.

## How it works

1. The web page loads `enterprise.js` with your site key, and calls
   `grecaptcha.enterprise.execute(siteKey, { action: 'homepage' })` to get a
   token.
2. The page POSTs `{ "recaptcha_token": "..." }` to this service's `/assess`
   endpoint.
3. This service calls
   [`projects.assessments.create`](https://cloud.google.com/recaptcha/docs/reference/rest/v1/projects.assessments/create)
   with the token, the site key, the expected action, and the caller's user
   agent and IP address.
4. The service returns a `summary` (validity, action, score, reasons) and the
   full `assessment`, with the token shortened.

The service runs as a dedicated service account with
`roles/recaptchaenterprise.agent`. It scales to zero, and allows
unauthenticated access, because browsers call it directly. CORS is limited to
the origins in `ALLOWED_ORIGINS`.

## Cost and exposure

The `/assess` endpoint does not authenticate callers. Anyone who learns its
URL can call it, and each call creates an assessment in your project.
Assessments beyond the monthly free tier are billed; see
[reCAPTCHA pricing](https://cloud.google.com/recaptcha/pricing). CORS does not
prevent this, because it only constrains browsers.

The deploy script caps the service at 2 instances. That limits throughput, not
cost. For anything beyond a demo, put the service behind something that
authenticates or rate-limits callers, such as an API gateway, or delete the
service when you are done (see [Cleanup](#cleanup)).

## Prerequisites

- gcloud
- curl
- a Google Cloud project with billing enabled, and rights to enable APIs,
  create service accounts, grant roles, and deploy Cloud Run services
- node 22+ and pnpm, only if you want to run the service locally

## Setup

Edit `env.sh` once:

- Set `CLOUDRUN_PROJECT_ID` to your project.
- `RECAPTCHA_KEY_DOMAINS` lists the domains allowed to generate tokens with
  your key. `ALLOWED_ORIGINS` lists the origins allowed to call the service
  from a browser. The defaults allow the demo page at `dinochiesa.github.io`
  and `localhost`. If you host your own page, add its domain to both.

Then source it:

```sh
source ./env.sh
```

Then run the scripts in order:

```sh
./0-set-project-and-enable-apis.sh
./1-enable-cloud-build-roles.sh
./2-create-runtime-service-account.sh
./3-create-recaptcha-key.sh
# paste the "export RECAPTCHA_SITE_KEY=..." line that step 3 prints
./4-deploy-assessment-service.sh
./5-check-service.sh
```

Step 3 first looks for a key named `RECAPTCHA_KEY_DISPLAY_NAME`, and creates
one only if none exists, so re-running it is safe. The key is a **Web,
score-based** key restricted to `RECAPTCHA_KEY_DOMAINS`. That is the key type
the page needs. The script prints an `export` command; paste it into your
shell to set `RECAPTCHA_SITE_KEY` before step 4. If you start a new shell
later, source `env.sh` and re-run step 3 to get the command again.

Step 4 prints the endpoint URL, ending in `/assess`.

Step 5 sends a bogus token. Expect `"valid": false` with an `invalidReason`
such as `MALFORMED`. That shows the service is reachable and can call the
reCAPTCHA API.

## Try it with the demo page

1. Open <https://dinochiesa.github.io/recaptcha/>.
2. In **Assessment Endpoint URL**, enter the URL printed by step 4.
3. In **Enterprise Site Key**, enter the site key printed by step 3.
4. Click **Check Assessment**.

The page shows the JSON the service returns. A `score` near `1.0` means
reCAPTCHA thinks the request came from a human; near `0.0`, a bot. A new key
with little traffic often returns the reason `LOW_CONFIDENCE_SCORE`.

The page stores the endpoint URL and site key in your browser's
`localStorage`, and sends them nowhere except to Google (the site key) and to
your endpoint (the token).

## Configuration

The service reads these environment variables:

| Variable               | Meaning                                                   |
| ---------------------- | --------------------------------------------------------- |
| `RECAPTCHA_PROJECT_ID` | Project that owns the key; assessments are created here   |
| `RECAPTCHA_SITE_KEY`   | The site key the page uses                                |
| `EXPECTED_ACTION`      | Action the page passes to `execute()`; default `homepage` |
| `ALLOWED_ORIGINS`      | Comma-separated CORS origins; if empty, any origin        |

## Running locally

To test without deploying to Cloud Run, run steps 0 and 3, paste the
`export` command, and then:

```sh
gcloud auth application-default login   # once
./4-deploy-assessment-service.sh --local
```

The service listens on `http://localhost:$LOCAL_PORT` (default 5150) until you
press Ctrl-C. In the web page, use `http://localhost:5150/assess` as the
endpoint URL. In another shell (after `source ./env.sh`):

```sh
./5-check-service.sh --local
```

Locally, the service calls the reCAPTCHA API with your own Application Default
Credentials, not the runtime service account. Your account needs permission
to create assessments in `RECAPTCHA_PROJECT_ID`; project Owner or Editor is
enough, or `roles/recaptchaenterprise.agent`.

## Cleanup

```sh
./r1-remove-service.sh
```

This deletes the service and the service account. It leaves the reCAPTCHA key
in place, and prints the command to delete it.

## License

This material is [Copyright © 2026 Google LLC](./NOTICE) and is licensed under
the [Apache 2.0 License](LICENSE).
