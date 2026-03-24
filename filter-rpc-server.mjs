import http from "node:http";
import { spawn } from "node:child_process";

const PORT = Number(process.env.PORT || 8787);
const HOST = process.env.HOST || "127.0.0.1";
const TOKEN = process.env.FILTER_RPC_TOKEN || "";
const BASE_URL = process.env.ELYSIA_BASE_URL || "https://elysia.xpress1.cc";
const RUNNER = process.env.RUNNER || "/home/dev/reglas-filtrado/run-filter-job.sh";
const ALLOWED_IPS = new Set(
  String(process.env.FILTER_RPC_ALLOWED_IPS || "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean)
);

function log(event, payload = {}) {
  console.log(JSON.stringify({
    ts: new Date().toISOString(),
    event,
    ...payload,
  }));
}

function send(res, status, data) {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(data));
}

function getRemoteIp(req) {
  const forwarded = String(req.headers["cf-connecting-ip"] || "").trim();
  if (forwarded) return forwarded;
  const raw = String(req.socket.remoteAddress || "").trim();
  return raw.replace(/^::ffff:/, "");
}

function isLoopback(ip) {
  return ip === "127.0.0.1" || ip === "::1" || ip === "localhost";
}

const server = http.createServer((req, res) => {
  if (req.method !== "POST" || req.url !== "/run") {
    return send(res, 404, { ok: false, error: "not_found" });
  }

  if (TOKEN && req.headers["x-filter-token"] !== TOKEN) {
    log("unauthorized", { remote_ip: getRemoteIp(req) });
    return send(res, 401, { ok: false, error: "unauthorized" });
  }

  const remoteIp = getRemoteIp(req);
  if (ALLOWED_IPS.size > 0 && !ALLOWED_IPS.has(remoteIp) && !isLoopback(remoteIp)) {
    log("forbidden_ip", { remote_ip: remoteIp });
    return send(res, 403, {
      ok: false,
      error: "forbidden_ip",
      remote_ip: remoteIp,
    });
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
      log("missing_solicitud_id", { remote_ip: remoteIp });
      return send(res, 400, { ok: false, error: "missing_solicitud_id" });
    }

    log("job_received", { remote_ip: remoteIp, solicitud_id: solicitudId, mode });

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
        log("job_failed", { solicitud_id: solicitudId, mode, code });
        return send(res, code === 3 ? 409 : 500, {
          ok: false,
          error: "runner_failed",
          code,
          stdout,
          stderr,
        });
      }

      try {
        log("job_finished", { solicitud_id: solicitudId, mode });
        return send(res, 200, JSON.parse(stdout));
      } catch {
        log("invalid_runner_output", { solicitud_id: solicitudId, mode });
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
  console.log(JSON.stringify({
    ok: true,
    host: HOST,
    port: PORT,
    runner: RUNNER,
    allowed_ips: Array.from(ALLOWED_IPS),
  }));
});
