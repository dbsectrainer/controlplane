"""
Compliance Reporter — local demo dashboard
Reads SOC2/HIPAA/PCI controls YAML files and serves a live dashboard.
POST /inject-drift?framework=soc2&control=CC1.0  — simulate a control failure
POST /restore                                      — restore all controls to passing
"""

# pyright: reportMissingImports=false, reportMissingModuleSource=false

import os
import glob
import yaml
import threading
import time
from flask import Flask, jsonify, request, render_template_string
from prometheus_client import Gauge, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

COMPLIANCE_DIR = os.environ.get("COMPLIANCE_DIR", "./compliance")

# Prometheus metrics
control_status = Gauge(
    "compliance_control_status",
    "Compliance control status (1=pass, 0=fail)",
    ["framework", "control", "title"],
)
controls_failing_total = Gauge(
    "compliance_controls_failing_total",
    "Total number of failing compliance controls",
    ["framework"],
)

# In-memory drift state: {framework: {control_id: bool}}
_drift: dict = {}
_lock = threading.Lock()


def load_controls() -> dict:
    """Parse all controls YAML files and return structured dict."""
    frameworks = {}
    for yaml_file in glob.glob(f"{COMPLIANCE_DIR}/**/*.yaml", recursive=True):
        try:
            with open(yaml_file) as f:
                docs = list(yaml.safe_load_all(f))
            for doc in docs:
                if not doc or doc.get("kind") != "ComplianceControl":
                    continue
                spec = doc.get("spec", {})
                fw = spec.get("framework", "UNKNOWN")
                ctrl_id = spec.get("control", "UNKNOWN")
                if fw not in frameworks:
                    frameworks[fw] = []
                frameworks[fw].append(
                    {
                        "id": ctrl_id,
                        "title": spec.get("title", ctrl_id),
                        "category": spec.get("category", ""),
                        "requirements": spec.get("requirements", []),
                    }
                )
        except Exception:
            pass
    return frameworks


def get_status(framework: str, control_id: str) -> str:
    with _lock:
        return "FAIL" if _drift.get(framework, {}).get(control_id) else "PASS"


def update_metrics(controls: dict) -> None:
    for fw, ctrl_list in controls.items():
        failing = 0
        for ctrl in ctrl_list:
            status = get_status(fw, ctrl["id"])
            val = 0 if status == "FAIL" else 1
            control_status.labels(
                framework=fw, control=ctrl["id"], title=ctrl["title"]
            ).set(val)
            if status == "FAIL":
                failing += 1
        controls_failing_total.labels(framework=fw).set(failing)


DASHBOARD_HTML = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Compliance Reporter</title>
  <meta http-equiv="refresh" content="10">
  <style>
    body { font-family: monospace; background: #0d1117; color: #c9d1d9; margin: 2rem; }
    h1 { color: #58a6ff; }
    h2 { color: #79c0ff; border-bottom: 1px solid #30363d; padding-bottom: 4px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 2rem; }
    th { background: #161b22; color: #8b949e; text-align: left; padding: 6px 12px; }
    td { padding: 6px 12px; border-bottom: 1px solid #21262d; }
    .PASS { color: #3fb950; font-weight: bold; }
    .FAIL { color: #f85149; font-weight: bold; }
    .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.8em; }
    .badge-pass { background: #1a4a2e; color: #3fb950; }
    .badge-fail { background: #4a1a1a; color: #f85149; }
    small { color: #6e7681; }
  </style>
</head>
<body>
  <h1>Security Compliance Dashboard</h1>
  <small>Auto-refreshes every 10s &mdash; POST /inject-drift?framework=SOC2&control=CC1.0 to simulate drift</small>
  {% for fw, controls in data.items() %}
  <h2>{{ fw }}</h2>
  <table>
    <tr><th>Control ID</th><th>Title</th><th>Category</th><th>Status</th></tr>
    {% for ctrl in controls %}
    <tr>
      <td>{{ ctrl.id }}</td>
      <td>{{ ctrl.title }}</td>
      <td>{{ ctrl.category }}</td>
      <td><span class="badge badge-{{ ctrl.status.lower() }}">{{ ctrl.status }}</span></td>
    </tr>
    {% endfor %}
  </table>
  {% endfor %}
</body>
</html>
"""


@app.route("/")
@app.route("/dashboard")
def dashboard():
    controls = load_controls()
    update_metrics(controls)
    data = {}
    for fw, ctrl_list in controls.items():
        data[fw] = [
            {**c, "status": get_status(fw, c["id"])}
            for c in ctrl_list
        ]
    return render_template_string(DASHBOARD_HTML, data=data)


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


@app.route("/metrics")
def metrics():
    controls = load_controls()
    update_metrics(controls)
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.route("/api/controls")
def api_controls():
    controls = load_controls()
    result = {}
    for fw, ctrl_list in controls.items():
        result[fw] = [
            {**c, "status": get_status(fw, c["id"])}
            for c in ctrl_list
        ]
    return jsonify(result)


@app.route("/inject-drift", methods=["POST"])
def inject_drift():
    """Simulate a compliance control failure for demo scenario 3."""
    framework = request.args.get("framework", "SOC2").upper()
    control = request.args.get("control", "CC1.0")
    with _lock:
        _drift.setdefault(framework, {})[control] = True
    return jsonify({"injected": True, "framework": framework, "control": control})


@app.route("/restore", methods=["POST"])
def restore():
    """Restore all controls to passing state."""
    with _lock:
        _drift.clear()
    return jsonify({"restored": True})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8088))
    app.run(host="0.0.0.0", port=port)
