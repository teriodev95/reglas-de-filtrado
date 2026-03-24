import http from "node:http";
import { spawn } from "node:child_process";

const PORT = Number(process.env.PORT || 8787);
const HOST = process.env.HOST || "127.0.0.1";
const TOKEN = process.env.FILTER_RPC_TOKEN || "";
const BASE_URL = process.env.ELYSIA_BASE_URL || "https://elysia.xpress1.cc";
const RUNNER = process.env.RUNNER || "/home/dev/reglas-filtrado/run-filter-job.sh";

function send(res, status, data) {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(data));
}

const server = http.createServer((req, res) => {
  if (req.method !== "POST" || req.url !== "/run") {
    return send(res, 404, { ok: false, error: "not_found" });
  }

  if (TOKEN && req.headers["x-filter-token"] !== TOKEN) {
    return send(res, 401, { ok: false, error: "unauthorized" });
  }

  let body = "";
  req.on("data", (chunk) => {
    body += chunk.toString();
  });

  req.on("end", () => {
    let parsed = {};
    try {
      parsed = body ? JSON.parse(body) : {};
    } catch (error) {
      return send(res, 400, { ok: false, error: "invalid_json", message: String(error) });
    }

    const solicitudId = String(parsed.solicitud_id || "").trim();
    const mode = parsed.mode === "apply" ? "apply" : "dry-run";

    if (!solicitudId) {
      return send(res, 400, { ok: false, error: "missing_solicitud_id" });
    }

    const child = spawn(RUNNER, [solicitudId, mode], {
      env: {
        ...process.env,
        ELYSIA_BASE_URL: parsed.base_url || BASE_URL,
      },
    });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    child.on("close", (code) => {
      if (code !== 0) {
        return send(res, code === 3 ? 409 : 500, {
          ok: false,
          error: "runner_failed",
          code,
          stdout,
          stderr,
        });
      }

      try {
        return send(res, 200, JSON.parse(stdout));
      } catch {
        return send(res, 500, {
          ok: false,
          error: "invalid_runner_output",
          stdout,
          stderr,
        });
      }
    });
  });
});

server.listen(PORT, HOST, () => {
  console.log(JSON.stringify({ ok: true, host: HOST, port: PORT, runner: RUNNER }));
});
