# Decisions API Worker

The browser calls this Worker. The OpenAI key stays in the Worker secret store;
the Worker only forwards a short context and one fixed choice question to the
official `POST /v1/decisions` endpoint. It maps the returned choice to trusted
Japanese copy, validates the result, limits requests to 12 per visitor per
minute, and applies an eight-second upstream timeout.

## Local run

Create `.dev.vars` at the repository root with an `OPENAI_API_KEY` entry. Keep
that file local and never commit or upload it.

```sh
npx wrangler@4.36.0 --config wrangler.toml dev --env local --local
```

The Worker is available at `http://127.0.0.1:8787/api/decision`. The `local`
Wrangler environment allows `http://127.0.0.1:8765`; production only allows the
GitHub Pages origin.

## Deploy

Authenticate Wrangler with the Cloudflare account that owns the
`workers.dev` subdomain, then add the key as a Worker secret and deploy:

```sh
npx wrangler@4.36.0 --config wrangler.toml login
npx wrangler@4.36.0 --config wrangler.toml secret put OPENAI_API_KEY
npx wrangler@4.36.0 --config wrangler.toml deploy
```

After deployment, set the Worker URL in the Godot project’s
`escape_fort_mason/decisions_endpoint` setting. The key is never a Godot project
setting. The deployer must have Worker deployment permission; no account token
or key belongs in this repository.

## Tests

```sh
node --test worker.test.mjs
```
