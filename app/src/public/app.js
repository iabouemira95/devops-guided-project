const recentRequests = [];
let currentUiConfig = null;

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

async function fetchJson(url, options = {}) {
  const startedAt = performance.now();
  const response = await fetch(url, options);
  const contentType = response.headers.get("content-type") || "";
  const body = contentType.includes("application/json")
    ? await response.json()
    : await response.text();

  return {
    ok: response.ok,
    status: response.status,
    body,
    requestId: response.headers.get("x-request-id"),
    durationMs: Number((performance.now() - startedAt).toFixed(2)),
    url
  };
}

function setOutput(title, payload) {
  const output = document.getElementById("response-output");
  output.textContent = `${title}\n\n${JSON.stringify(payload, null, 2)}`;
}

function renderSimulationContext(apiInfo) {
  const container = document.getElementById("simulation-context");
  container.innerHTML = `
    <p><strong>${escapeHtml(apiInfo.scenario_name)}</strong> is used to simulate a small but realistic library circulation service.</p>
    <ul class="detail-list">
      <li><strong>Team:</strong> ${escapeHtml(apiInfo.team_name)}</li>
      <li><strong>Profile:</strong> ${escapeHtml(apiInfo.simulation_profile)}</li>
      <li><strong>Services:</strong> ${apiInfo.supported_services.map(escapeHtml).join(", ")}</li>
      <li><strong>Environments:</strong> ${apiInfo.environments.map(escapeHtml).join(", ")}</li>
      <li><strong>Regions:</strong> ${apiInfo.regions.map(escapeHtml).join(", ")}</li>
    </ul>
    <p class="hint">${escapeHtml(apiInfo.dataset_note)}</p>
  `;
}

function formatTopEntries(entries = {}) {
  return Object.entries(entries)
    .slice(0, 4)
    .map(([label, count]) => `${label}: ${count}`)
    .join(" | ");
}

function renderDatasetSnapshot(payload = {}) {
  const snapshot = document.getElementById("dataset-snapshot");
  const items = payload.items || payload.recent_items || [];
  const summary = payload.summary;

  if (!summary || !items.length) {
    snapshot.innerHTML =
      "Run <strong>Load Library Records</strong> or <strong>Create Demo Checkout</strong> to inspect the simulated library dataset.";
    return;
  }

  snapshot.innerHTML = `
    <dl class="summary-grid">
      <div class="summary-item"><dt>Total Records</dt><dd>${escapeHtml(summary.total_items)}</dd></div>
      <div class="summary-item"><dt>Loan Status</dt><dd>${escapeHtml(formatTopEntries(summary.by_status))}</dd></div>
      <div class="summary-item"><dt>Priority</dt><dd>${escapeHtml(formatTopEntries(summary.by_priority))}</dd></div>
      <div class="summary-item"><dt>Workflow Areas</dt><dd>${escapeHtml(formatTopEntries(summary.by_workflow_area || summary.by_service))}</dd></div>
    </dl>
    <table class="dataset-table">
      <thead>
        <tr>
          <th>Book Title</th>
          <th>Workflow</th>
          <th>Status</th>
          <th>Borrower</th>
          <th>Due Date</th>
        </tr>
      </thead>
      <tbody>
        ${items
          .slice(0, 5)
          .map(
            (item) => `
              <tr>
                <td>${escapeHtml(item.book_title || item.name)}</td>
                <td>${escapeHtml(item.workflow_area || item.service)}</td>
                <td>${escapeHtml(item.loan_status || item.status)}</td>
                <td>${escapeHtml(item.borrower_name || item.member_name || item.owner_name)}</td>
                <td>${escapeHtml(item.due_date || "n/a")}</td>
              </tr>
            `
          )
          .join("")}
      </tbody>
    </table>
  `;
}

const actionGuides = {
  health: {
    title: "Check Health",
    route: "GET /health",
    tags: ["Nginx", "Express", "request_id", "logs", "metrics"],
    dependencies: "No external dependency checks are needed for this route.",
    flow: [
      "Browser clicks the Health button and Nginx receives the request first.",
      "Nginx forwards the request to the Express app on port 3000.",
      "The app creates an X-Request-Id, returns process health, and writes a structured request log.",
      "Prometheus metrics increase for the /health path, and Nginx writes an access log entry."
    ],
    checks: [
      "In app logs, find the request_id for GET /health.",
      "In Nginx access logs, confirm the same path returned 200.",
      "In Prometheus or Grafana, verify request counters move for /health."
    ]
  },
  ready: {
    title: "Check Readiness",
    route: "GET /ready",
    tags: ["Nginx", "Express", "PostgreSQL", "Redis", "readiness gauges"],
    dependencies: "This route actively checks PostgreSQL and Redis before returning.",
    flow: [
      "Nginx forwards GET /ready to the app.",
      "The app checks PostgreSQL connectivity and Redis connectivity.",
      "The response reports db_ready and redis_ready, and the readiness gauges are updated.",
      "The request produces one app log line and one Nginx access log line."
    ],
    checks: [
      "Confirm db_ready_status and redis_ready_status in Prometheus/Grafana.",
      "If /ready is slow, compare app logs with PostgreSQL and Redis container logs.",
      "Use the request_id in the response headers to correlate the request in app logs."
    ]
  },
  version: {
    title: "Show Version",
    route: "GET /version",
    tags: ["version", "image tag", "environment", "deploy metadata"],
    dependencies: "This route reads deployment metadata already loaded into the app environment.",
    flow: [
      "Nginx forwards GET /version to the app.",
      "The app returns build metadata from environment variables.",
      "This is the same metadata students should verify after CI and VM deployment.",
      "The request is visible in both Nginx access logs and app request logs."
    ],
    checks: [
      "Match image_tag and git_sha against the deployed image you expect.",
      "Use this route after a new deployment to prove what version is actually running."
    ]
  },
  items: {
    title: "Load Library Records",
    route: "GET /items",
    tags: ["PostgreSQL", "library dataset", "summary view", "slow path candidate"],
    dependencies: "This route reads circulation records from PostgreSQL and summarizes them for the GUI.",
    flow: [
      "The app receives GET /items after Nginx forwards it.",
      "The app queries PostgreSQL for the circulation records table.",
      "Results are returned with book, borrower, branch, and due-date fields plus one request_id.",
      "This request is a good way to compare app latency with realistic database-backed work."
    ],
    checks: [
      "If this route is slow, compare app logs, PostgreSQL container logs, and request duration metrics.",
      "Confirm the returned records include realistic seeded library circulation data from db/init.sql."
    ]
  },
  "create-item": {
    title: "Create Demo Checkout",
    route: "POST /items",
    tags: ["PostgreSQL", "write path", "structured logs"],
    dependencies: "This route writes a new circulation record to PostgreSQL, then reloads the latest summary.",
    flow: [
      "The browser sends POST /items and Nginx forwards it to the app.",
      "The app writes a new simulated library circulation row to PostgreSQL and returns HTTP 201.",
      "The new record can be confirmed immediately with the Load Library Records button or the dataset snapshot.",
      "The app and Nginx logs should both show the POST path and created status."
    ],
    checks: [
      "Look for a 201 status in app logs and Nginx access logs.",
      "Load records again to confirm the new simulated checkout persisted."
    ]
  },
  "cache-demo": {
    title: "Test Popular Titles Cache",
    route: "GET /cache-demo",
    tags: ["Redis", "cache hit/miss", "request flow"],
    dependencies: "This route checks Redis first, then generates and stores a payload if the cache is empty.",
    flow: [
      "Nginx forwards GET /cache-demo to the app.",
      "The app asks Redis for the cached value first.",
      "If no cached value exists, the app generates a small popular-titles snapshot and stores it in Redis.",
      "A second run should show the cached source rather than the app-generated source."
    ],
    checks: [
      "Run the button twice and compare the source field.",
      "If Redis is down, /ready should degrade and this route should fail visibly."
    ]
  },
  slow: {
    title: "Generate Slow Request",
    route: "GET /slow",
    tags: ["latency", "logs", "histogram", "Grafana"],
    dependencies: "This route stays inside the app but intentionally waits before sending the response.",
    flow: [
      "Nginx forwards GET /slow to the app.",
      "The app intentionally waits 2500 ms before responding.",
      "The app log records the higher duration_ms and Prometheus updates the latency histogram.",
      "This is the fastest way to create a visible latency spike for students."
    ],
    checks: [
      "In app logs, find the request_id and duration_ms for /slow.",
      "In Grafana, inspect latency panels after triggering this route."
    ]
  },
  error: {
    title: "Generate Error",
    route: "GET /error",
    tags: ["500", "error log", "Nginx", "metrics"],
    dependencies: "This route intentionally raises an application error after the request reaches Express.",
    flow: [
      "Nginx forwards GET /error to the app.",
      "The app raises the intentional training error and returns HTTP 500.",
      "The error middleware writes an error-level log with the request_id.",
      "Metrics and Nginx access logs both record the failing request."
    ],
    checks: [
      "Find status_code 500 in app and Nginx logs.",
      "Use the request_id from the GUI response to locate the error log line.",
      "Confirm error counters move in Grafana or Prometheus."
    ]
  }
};

function getPillClass(value) {
  if (value === "ready" || value === "healthy" || value === "observed" || value === "200" || value === "201") {
    return "pill pill-ok";
  }

  if (value === "running" || value === "in-flight") {
    return "pill pill-progress";
  }

  if (value === "warning" || value === "degraded") {
    return "pill pill-warn";
  }

  if (value === "500" || value === "failed") {
    return "pill pill-error";
  }

  return "pill pill-neutral";
}

function toDisplayState(action, result) {
  const guide = actionGuides[action];
  const payload = result.body && typeof result.body === "object" ? result.body : {};
  const source = payload.source || payload.value?.cache_key || payload.status || "app-response";
  const statusLabel = String(result.status);
  const dependencyState =
    action === "ready"
      ? payload.db_ready && payload.redis_ready
        ? "ready"
        : "degraded"
      : action === "items" || action === "create-item"
        ? "PostgreSQL"
        : action === "cache-demo"
          ? payload.source === "redis-cache"
            ? "redis-hit"
            : "redis-write"
          : guide?.dependencies || "app-only";

  return {
    title: guide?.title || action,
    route: guide?.route || result.url,
    statusLabel,
    requestId: result.requestId || "n/a",
    durationMs: result.durationMs,
    source,
    dependencyState
  };
}

function renderGuide(action) {
  const guide = actionGuides[action];
  const flowContainer = document.getElementById("request-flow");
  const checklistContainer = document.getElementById("request-checklist");

  if (!guide) {
    flowContainer.textContent = "Choose a traffic button to load the request path.";
    checklistContainer.textContent = "Run one request to see the related checks.";
    return;
  }

  flowContainer.innerHTML = `
    <p><strong>${escapeHtml(guide.title)}</strong> uses <code>${escapeHtml(guide.route)}</code>.</p>
    <div>${guide.tags.map((tag) => `<span class="flow-tag">${escapeHtml(tag)}</span>`).join("")}</div>
    <p class="hint"><strong>Dependency focus:</strong> ${escapeHtml(guide.dependencies)}</p>
    <ol class="flow-list">
      ${guide.flow.map((step) => `<li>${escapeHtml(step)}</li>`).join("")}
    </ol>
  `;

  checklistContainer.innerHTML = `
    <ol class="check-list">
      ${guide.checks.map((step) => `<li>${escapeHtml(step)}</li>`).join("")}
    </ol>
  `;
}

function renderLiveRequestState(action, result = null) {
  const guide = actionGuides[action];
  const container = document.getElementById("live-request-state");

  if (!guide) {
    container.textContent =
      "Trigger a request to watch the ingress, app handling, dependency work, and observability hints update together.";
    return;
  }

  const state = result ? toDisplayState(action, result) : null;
  const ingress = state ? (result.status >= 400 ? "500" : "200") : "in-flight";
  const appState = state ? (result.status >= 400 ? "failed" : "healthy") : "running";
  const dependencyState = state
    ? result.status >= 500 && action === "error"
      ? "warning"
      : action === "ready"
        ? state.dependencyState
        : "observed"
    : "running";
  const observabilityState = state ? "observed" : "running";

  container.innerHTML = `
    <p><strong>${escapeHtml(guide.title)}</strong> is mapped to <code>${escapeHtml(guide.route)}</code>.</p>
    <dl class="status-grid">
      <div class="status-card">
        <dt>Ingress</dt>
        <dd><span class="${getPillClass(ingress)}">${escapeHtml(ingress === "200" ? "Nginx forwarded" : ingress)}</span><small>Public request entry point</small></dd>
      </div>
      <div class="status-card">
        <dt>App</dt>
        <dd><span class="${getPillClass(appState)}">${escapeHtml(appState)}</span><small>Express request handling</small></dd>
      </div>
      <div class="status-card">
        <dt>Dependency</dt>
        <dd><span class="${getPillClass(dependencyState)}">${escapeHtml(dependencyState)}</span><small>${escapeHtml(guide.dependencies)}</small></dd>
      </div>
      <div class="status-card">
        <dt>Observability</dt>
        <dd><span class="${getPillClass(observabilityState)}">${escapeHtml(observabilityState)}</span><small>Logs and metrics should now reflect this request</small></dd>
      </div>
    </dl>
    <ul class="timeline-list">
      <li><strong>Request:</strong> ${escapeHtml(guide.route)}</li>
      <li><strong>Request ID:</strong> <span class="mono">${escapeHtml(state?.requestId || "pending")}</span></li>
      <li><strong>Browser duration:</strong> ${escapeHtml(state ? `${state.durationMs} ms` : "Waiting for response")}</li>
    </ul>
  `;
}

function renderRecentTrail() {
  const container = document.getElementById("recent-request-trail");

  if (!recentRequests.length) {
    container.textContent =
      "Your last few actions will appear here with request IDs, status codes, and durations so you can follow the request cycle step by step.";
    return;
  }

  container.innerHTML = `
    <table class="trail-table">
      <thead>
        <tr>
          <th>Action</th>
          <th>Status</th>
          <th>Request ID</th>
          <th>Duration</th>
        </tr>
      </thead>
      <tbody>
        ${recentRequests
          .map(
            (entry) => `
              <tr>
                <td>${escapeHtml(entry.title)}<div class="hint">${escapeHtml(entry.route)}</div></td>
                <td><span class="${getPillClass(String(entry.status))}">${escapeHtml(String(entry.status))}</span></td>
                <td class="mono">${escapeHtml(entry.requestId || "n/a")}</td>
                <td>${escapeHtml(`${entry.durationMs} ms`)}</td>
              </tr>
            `
          )
          .join("")}
      </tbody>
    </table>
  `;
}

function renderResponseSummary(action, result = null) {
  const guide = actionGuides[action];
  const container = document.getElementById("response-summary");

  if (!guide || !result) {
    container.textContent =
      "Run a request to see the request ID, duration, source, and suggested next checks.";
    return;
  }

  const state = toDisplayState(action, result);
  const payload = result.body && typeof result.body === "object" ? result.body : {};
  const nextCheck = guide.checks[0] || "Review the related logs and metrics.";

  container.innerHTML = `
    <dl class="summary-stack">
      <div class="summary-row"><dt>Action</dt><dd>${escapeHtml(state.title)}</dd></div>
      <div class="summary-row"><dt>Status</dt><dd><span class="${getPillClass(state.statusLabel)}">${escapeHtml(state.statusLabel)}</span></dd></div>
      <div class="summary-row"><dt>Request ID</dt><dd class="mono">${escapeHtml(state.requestId)}</dd></div>
      <div class="summary-row"><dt>Browser Duration</dt><dd>${escapeHtml(`${state.durationMs} ms`)}</dd></div>
      <div class="summary-row"><dt>Payload Source</dt><dd>${escapeHtml(payload.source || payload.status || "app-response")}</dd></div>
      <div class="summary-row"><dt>Next Check</dt><dd>${escapeHtml(nextCheck)}</dd></div>
    </dl>
  `;
}

function renderOperationalNotes(action, result = null) {
  const guide = actionGuides[action];
  const container = document.getElementById("operational-notes");

  if (!guide || !result) {
    container.innerHTML = `
      <ul class="notes-list">
        <li>Use one GUI action at a time so the request IDs are easy to follow.</li>
        <li>Compare the response panel with app logs, Nginx access logs, and Grafana.</li>
        <li>Use <strong>Generate Slow Request</strong> and <strong>Generate Error</strong> to create visible signals for troubleshooting.</li>
      </ul>
    `;
    return;
  }

  const notes = [
    `Use request ID ${result.requestId || "n/a"} to find the matching app log lines.`,
    `Check the Nginx access log for ${guide.route} and confirm the HTTP status ${result.status}.`,
    currentUiConfig?.hint || "Open Grafana or Prometheus from the shortcuts after generating traffic."
  ];

  container.innerHTML = `
    <ul class="notes-list">
      ${notes.map((note) => `<li>${escapeHtml(note)}</li>`).join("")}
    </ul>
  `;
}

function configureShortcutButtons(config) {
  currentUiConfig = config;
  const hint = document.getElementById("observability-hint");
  hint.textContent = config.hint;

  document.querySelectorAll("[data-link-key]").forEach((button) => {
    const key = button.getAttribute("data-link-key");
    const target = config[key];

    if (!target) {
      button.disabled = true;
      button.title = "This shortcut is not available in the current runtime configuration.";
      return;
    }

    button.disabled = false;
    button.setAttribute("data-link", target);
    button.title = target;
  });
}

async function loadMetadata() {
  const [apiInfo, versionInfo, uiConfig] = await Promise.all([
    fetchJson("/api"),
    fetchJson("/version"),
    fetchJson("/ui-config")
  ]);

  const meta = {
    service_name: apiInfo.body.service_name,
    version: versionInfo.body.app_version,
    environment: apiInfo.body.environment,
    image_tag: versionInfo.body.image_tag,
    observability_mode: uiConfig.body.observability_mode
  };

  const container = document.getElementById("service-meta");
  container.innerHTML = `
    <div><dt>Service</dt><dd>${escapeHtml(meta.service_name)}</dd></div>
    <div><dt>Version</dt><dd>${escapeHtml(meta.version)}</dd></div>
    <div><dt>Environment</dt><dd>${escapeHtml(meta.environment)}</dd></div>
    <div><dt>Image Tag</dt><dd>${escapeHtml(meta.image_tag)}</dd></div>
  `;

  renderSimulationContext(apiInfo.body);
  configureShortcutButtons(uiConfig.body);
  renderOperationalNotes();
}

function setActionButtonsDisabled(disabled, activeAction = "") {
  document.querySelectorAll("[data-action]").forEach((button) => {
    const isActive = button.getAttribute("data-action") === activeAction;
    button.disabled = disabled;
    button.classList.toggle("is-loading", disabled && isActive);
  });
}

const actions = {
  async health() {
    return fetchJson("/health");
  },
  async ready() {
    return fetchJson("/ready");
  },
  async version() {
    return fetchJson("/version");
  },
  async items() {
    return fetchJson("/items");
  },
  async "create-item"() {
    return fetchJson("/items", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ book_title: "Site Reliability Engineering", member_name: "Demo Borrower" })
    });
  },
  async "cache-demo"() {
    return fetchJson("/cache-demo");
  },
  async slow() {
    return fetchJson("/slow");
  },
  async error() {
    return fetchJson("/error");
  }
};

document.addEventListener("click", async (event) => {
  const action = event.target.getAttribute("data-action");
  const link = event.target.getAttribute("data-link");

  if (link) {
    window.open(link, "_blank", "noopener");
    return;
  }

  if (!action) {
    return;
  }

  renderGuide(action);
  renderLiveRequestState(action);
  setOutput("Working…", { action });
  setActionButtonsDisabled(true, action);

  try {
    const result = await actions[action]();
    renderDatasetSnapshot(result.body);
    renderLiveRequestState(action, result);
    renderResponseSummary(action, result);
    renderOperationalNotes(action, result);

    recentRequests.unshift({
      ...toDisplayState(action, result),
      status: result.status
    });
    recentRequests.splice(5);
    renderRecentTrail();

    setOutput(`${action} -> HTTP ${result.status}`, {
      request_id: result.requestId,
      browser_duration_ms: result.durationMs,
      payload: result.body
    });
  } catch (error) {
    renderResponseSummary(action);
    renderOperationalNotes();
    setOutput("Request failed", { message: error.message });
  } finally {
    setActionButtonsDisabled(false);
  }
});

loadMetadata().catch((error) => {
  setOutput("Metadata load failed", { message: error.message });
});
