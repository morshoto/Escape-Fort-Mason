import assert from "node:assert/strict";
import test from "node:test";

import { handleRequest } from "./worker.mjs";

const allowedOrigin = "https://morshoto.github.io";

function makeEnv(overrides = {}) {
	return {
		OPENAI_API_KEY: "test-only-secret",
		ALLOWED_ORIGIN: allowedOrigin,
		RATE_LIMITER: { limit: async () => ({ success: true }) },
		...overrides,
	};
}

function makeRequest({ method = "POST", origin = allowedOrigin, body } = {}) {
	return new Request("https://worker.example/api/decision", {
		method,
		headers: {
			...(origin ? { Origin: origin } : {}),
			...(body === undefined ? {} : { "Content-Type": "application/json" }),
		},
		...(body === undefined ? {} : { body: JSON.stringify(body) }),
	});
}

async function responseBody(response) {
	return response.json();
}

test("answers one of the fixed actions and maps it to trusted Japanese copy", async () => {
	let forwardedRequest;
	const response = await handleRequest(
		makeRequest({ body: { context: "Sam entered the plaza." } }),
		makeEnv(),
		async (url, init) => {
			forwardedRequest = { url, init };
			return Response.json({
				answers: [{ type: "choice", name: "action", choice: "observe" }],
			});
		},
	);

	assert.equal(response.status, 200);
	assert.deepEqual(await responseBody(response), {
		action: "observe",
		message: "Fort Masonの景色を一緒に見よう。",
		source: "openai",
	});
	assert.equal(forwardedRequest.url, "https://api.openai.com/v1/decisions");
	assert.equal(forwardedRequest.init.headers.Authorization, "Bearer test-only-secret");
	const upstreamBody = JSON.parse(forwardedRequest.init.body);
	assert.equal(upstreamBody.model, "gpt-6-luna");
	assert.deepEqual(upstreamBody.questions[0].choices.map(({ value }) => value), [
		"greet",
		"observe",
		"wait",
	]);
	assert.match(upstreamBody.input, /Sam entered the plaza/);
});

test("preflight only grants the configured Pages origin", async () => {
	const response = await handleRequest(makeRequest({ method: "OPTIONS" }), makeEnv());

	assert.equal(response.status, 204);
	assert.equal(response.headers.get("Access-Control-Allow-Origin"), allowedOrigin);
	assert.match(response.headers.get("Access-Control-Allow-Methods"), /POST/);

	const denied = await handleRequest(
		makeRequest({ method: "OPTIONS", origin: "https://attacker.example" }),
		makeEnv(),
	);
	assert.equal(denied.status, 403);
	assert.equal(denied.headers.get("Access-Control-Allow-Origin"), null);
});

test("rejects arbitrary client action ids before contacting OpenAI", async () => {
	let upstreamCalled = false;
	const response = await handleRequest(
		makeRequest({ body: { context: "hello", action: "unlock_everything" } }),
		makeEnv(),
		async () => {
			upstreamCalled = true;
			return Response.json({});
		},
	);

	assert.equal(response.status, 400);
	assert.equal(upstreamCalled, false);
});

test("rejects a provider response outside the fixed choice set", async () => {
	const response = await handleRequest(
		makeRequest({ body: { context: "hello" } }),
		makeEnv(),
		async () => Response.json({
			answers: [{ type: "choice", name: "action", choice: "unlock_everything" }],
		}),
	);

	assert.equal(response.status, 502);
	assert.equal((await responseBody(response)).error, "invalid_provider_response");
});

test("returns a timeout response when the Decisions API times out", async () => {
	const response = await handleRequest(
		makeRequest({ body: { context: "hello" } }),
		makeEnv(),
		async () => {
			throw new DOMException("timed out", "TimeoutError");
		},
	);

	assert.equal(response.status, 504);
	assert.equal((await responseBody(response)).error, "upstream_timeout");
});

test("contains upstream HTTP errors without returning provider details", async () => {
	const response = await handleRequest(
		makeRequest({ body: { context: "hello" } }),
		makeEnv(),
		async () => new Response("private provider diagnostic", { status: 429 }),
	);

	assert.equal(response.status, 502);
	assert.equal((await responseBody(response)).error, "provider_unavailable");
});

test("fails closed when the OpenAI secret or rate-limit binding is missing", async () => {
	const noSecret = await handleRequest(
		makeRequest({ body: { context: "hello" } }),
		makeEnv({ OPENAI_API_KEY: "" }),
		async () => assert.fail("must not contact OpenAI without a secret"),
	);
	assert.equal(noSecret.status, 503);

	const noLimiter = await handleRequest(
		makeRequest({ body: { context: "hello" } }),
		makeEnv({ RATE_LIMITER: undefined }),
		async () => assert.fail("must not contact OpenAI without rate limiting"),
	);
	assert.equal(noLimiter.status, 503);
});

test("rate limits a visitor before spending an OpenAI request", async () => {
	let upstreamCalled = false;
	const response = await handleRequest(
		makeRequest({ body: { context: "hello" } }),
		makeEnv({ RATE_LIMITER: { limit: async () => ({ success: false }) } }),
		async () => {
			upstreamCalled = true;
			return Response.json({});
		},
	);

	assert.equal(response.status, 429);
	assert.equal(upstreamCalled, false);
});
