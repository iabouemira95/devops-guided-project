async function fetchJson(url, options = {}) {
  const response = await fetch(url, options);
  const contentType = response.headers.get("content-type") || "";
  const body = contentType.includes("application/json")
    ? await response.json()
    : await response.text();

  return {
    ok: response.ok,
    status: response.status,
    body,
    requestId: response.headers.get("x-request-id")
  };
}

function setOutput(title, payload) {
  const output = document.getElementById("response-output");
  output.textContent = `${title}\n\n${JSON.stringify(payload, null, 2)}`;
}

function renderSimulationContext(apiInfo) {
  const container = document.getElementById("simulation-context");
  container.innerHTML = `
    <p><strong>${apiInfo.scenario_name}</strong> is used to simulate a small but realistic library circulation service.</p>
    <ul class="detail-list">
      <li><strong>Team:</strong> ${apiInfo.team_name}</li>
      <li><strong>Profile:</strong> ${apiInfo.simulation_profile}</li>
      <li><strong>Services:</strong> ${apiInfo.supported_services.join(", ")}</li>
      <li><strong>Environments:</strong> ${apiInfo.environments.join(", ")}</li>
      <li><strong>Regions:</strong> ${apiInfo.regions.join(", ")}</li>
    </ul>
    <p class="hint">${apiInfo.dataset_note}</p>
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
      <div class="summary-item"><dt>Total Records</dt><dd>${summary.total_items}</dd></div>
      <div class="summary-item"><dt>Loan Status</dt><dd>${formatTopEntries(summary.by_status)}</dd></div>
      <div class="summary-item"><dt>Priority</dt><dd>${formatTopEntries(summary.by_priority)}</dd></div>
      <div class="summary-item"><dt>Workflow Areas</dt><dd>${formatTopEntries(summary.by_workflow_area || summary.by_service)}</dd></div>
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
                <td>${item.book_title || item.name}</td>
                <td>${item.workflow_area || item.service}</td>
                <td>${item.loan_status || item.status}</td>
                <td>${item.borrower_name || item.member_name || item.owner_name}</td>
                <td>${item.due_date || "n/a"}</td>
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
    <p><strong>${guide.title}</strong> uses <code>${guide.route}</code>.</p>
    <div>${guide.tags.map((tag) => `<span class="flow-tag">${tag}</span>`).join("")}</div>
    <ol class="flow-list">
      ${guide.flow.map((step) => `<li>${step}</li>`).join("")}
    </ol>
  `;

  checklistContainer.innerHTML = `
    <ol class="check-list">
      ${guide.checks.map((step) => `<li>${step}</li>`).join("")}
    </ol>
  `;
}

function configureShortcutButtons(config) {
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
    <div><dt>Service</dt><dd>${meta.service_name}</dd></div>
    <div><dt>Version</dt><dd>${meta.version}</dd></div>
    <div><dt>Environment</dt><dd>${meta.environment}</dd></div>
    <div><dt>Image Tag</dt><dd>${meta.image_tag}</dd></div>
  `;

  renderSimulationContext(apiInfo.body);
  configureShortcutButtons(uiConfig.body);
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
  setOutput("Working…", { action });

  try {
    const result = await actions[action]();
    renderDatasetSnapshot(result.body);
    setOutput(`${action} -> HTTP ${result.status}`, {
      request_id: result.requestId,
      payload: result.body
    });
  } catch (error) {
    setOutput("Request failed", { message: error.message });
  }
});

loadMetadata().catch((error) => {
  setOutput("Metadata load failed", { message: error.message });
});
