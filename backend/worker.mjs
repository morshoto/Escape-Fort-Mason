const OPENAI_DECISIONS_URL = "https://api.openai.com/v1/decisions";
const REQUEST_TIMEOUT_MS = 8_000;
const MAX_BODY_BYTES = 4_096;
const MAX_CONTEXT_CHARACTERS = 280;

const ACTIONS = Object.freeze({
	greet: {
		choice: "Greet Sam in Japanese.",
		message: "こんにちは、Sam！",
	},
	observe: {
		choice: "Invite Sam to look around in Japanese.",
		message: "Fort Masonの景色を一緒に見よう。",
	},
	wait: {
		choice: "Suggest waiting here in Japanese.",
		message: "少しここで待っていよう。",
	},
});

function jsonResponse(body, status, headers = {}) {
	return Response.json(body, {
		status,
		headers: {
			"Cache-Control": "no-store",
			"Content-Type": "application/json; charset=utf-8",
			...headers,
		},
	});
}

function corsHeaders(origin, env) {
	if (origin !== env.ALLOWED_ORIGIN) {
		return null;
	}
	return {
		"Access-Control-Allow-Origin": env.ALLOWED_ORIGIN,
		"Access-Control-Allow-Methods": "POST, OPTIONS",
		"Access-Control-Allow-Headers": "Content-Type",
		"Access-Control-Max-Age": "600",
		Vary: "Origin",
	};
}

function failure(code, status, headers) {
	return jsonResponse({ error: code }, status, headers);
}

function timeoutSignal() {
	return AbortSignal.timeout(REQUEST_TIMEOUT_MS);
}

export async function handleRequest(request, env, fetchImpl = fetch) {
	const origin = request.headers.get("Origin");
	const headers = corsHeaders(origin, env);
	if (headers === null) {
		return failure("origin_not_allowed", 403);
	}

	const url = new URL(request.url);
	if (url.pathname !== "/api/decision") {
		return failure("not_found", 404, headers);
	}
	if (request.method === "OPTIONS") {
		return new Response(null, { status: 204, headers });
	}
	if (request.method !== "POST") {
		return failure("method_not_allowed", 405, headers);
	}
	if (!request.headers.get("Content-Type")?.toLowerCase().startsWith("application/json")) {
		return failure("unsupported_media_type", 415, headers);
	}

	const declaredLength = Number(request.headers.get("Content-Length") ?? 0);
	if (declaredLength > MAX_BODY_BYTES) {
		return failure("request_too_large", 413, headers);
	}

	let rawBody;
	try {
		rawBody = await request.text();
	} catch {
		return failure("invalid_request", 400, headers);
	}
	if (new TextEncoder().encode(rawBody).byteLength > MAX_BODY_BYTES) {
		return failure("request_too_large", 413, headers);
	}

	let payload;
	try {
		payload = JSON.parse(rawBody);
	} catch {
		return failure("invalid_request", 400, headers);
	}
	if (
		payload === null
		|| typeof payload !== "object"
		|| Array.isArray(payload)
		|| Object.keys(payload).length !== 1
		|| typeof payload.context !== "string"
	) {
		return failure("invalid_request", 400, headers);
	}

	const context = payload.context.trim();
	if (context.length === 0 || context.length > MAX_CONTEXT_CHARACTERS) {
		return failure("invalid_context", 400, headers);
	}
	if (typeof env.OPENAI_API_KEY !== "string" || env.OPENAI_API_KEY.length === 0) {
		return failure("service_unavailable", 503, headers);
	}
	if (typeof env.RATE_LIMITER?.limit !== "function") {
		return failure("service_unavailable", 503, headers);
	}

	try {
		const clientIp = request.headers.get("CF-Connecting-IP") ?? "development";
		const limit = await env.RATE_LIMITER.limit({ key: clientIp });
		if (!limit.success) {
			return failure("rate_limited", 429, headers);
		}
	} catch {
		return failure("service_unavailable", 503, headers);
	}

	let upstream;
	try {
		upstream = await fetchImpl(OPENAI_DECISIONS_URL, {
			method: "POST",
			headers: {
				Authorization: `Bearer ${env.OPENAI_API_KEY}`,
				"Content-Type": "application/json",
			},
			signal: timeoutSignal(),
			body: JSON.stringify({
				model: "gpt-6-luna",
				input: context,
				questions: [{
					type: "choice",
					name: "action",
					instructions: "Choose the most appropriate next companion action for Sam.",
					choices: Object.entries(ACTIONS).map(([value, action]) => ({
						value,
						description: action.choice,
					})),
				}],
			}),
		});
	} catch (error) {
		return failure(error?.name === "TimeoutError" ? "upstream_timeout" : "provider_unavailable",
			error?.name === "TimeoutError" ? 504 : 502,
			headers,
		);
	}
	if (!upstream.ok) {
		return failure("provider_unavailable", 502, headers);
	}

	let providerResponse;
	try {
		providerResponse = await upstream.json();
	} catch {
		return failure("invalid_provider_response", 502, headers);
	}
	const answer = providerResponse?.answers?.find(
		(candidate) => candidate?.type === "choice" && candidate?.name === "action",
	);
	const action = answer?.choice;
	if (typeof action !== "string" || !Object.hasOwn(ACTIONS, action)) {
		return failure("invalid_provider_response", 502, headers);
	}

	return jsonResponse({
		action,
		message: ACTIONS[action].message,
		source: "openai",
	}, 200, headers);
}

export default {
	fetch(request, env) {
		return handleRequest(request, env);
	},
};
