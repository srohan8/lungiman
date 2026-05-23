/**
 * coi-serviceworker — makes GitHub Pages send the CORS headers that
 * Godot 4's web export needs (SharedArrayBuffer / Atomics).
 *
 * Based on https://github.com/gzuidhof/coi-serviceworker (MIT licence).
 * This file is committed to the repo so the CI can copy it into the build.
 */

self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", e => e.waitUntil(self.clients.claim()));

async function handleFetch(request) {
    // Avoid breaking opaque requests
    if (request.cache === "only-if-cached" && request.mode !== "same-origin") {
        return;
    }
    const r = await fetch(request);
    if (r.status === 0) return r;

    const headers = new Headers(r.headers);
    headers.set("Cross-Origin-Opener-Policy",   "same-origin");
    headers.set("Cross-Origin-Embedder-Policy", "require-corp");
    headers.set("Cross-Origin-Resource-Policy", "cross-origin");
    return new Response(r.body, {
        status:     r.status,
        statusText: r.statusText,
        headers,
    });
}

self.addEventListener("fetch", e => e.respondWith(handleFetch(e.request)));
