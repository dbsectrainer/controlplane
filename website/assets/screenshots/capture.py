#!/usr/bin/env python3
# pyright: reportMissingImports=false, reportMissingModuleSource=false
"""
Playwright screenshot capture for all portfolio Docker services.
Usage: python3 capture.py
Output: PNG files in the same directory as this script.
"""

import os
from pathlib import Path
from playwright.sync_api import sync_playwright

OUTPUT_DIR = Path(__file__).parent

SERVICES = [
    {"name": "demo-app",           "url": "http://localhost:3000",       "wait": "networkidle"},
    {"name": "grafana",            "url": "http://localhost:3100",       "wait": "networkidle"},
    {"name": "mobsf",              "url": "http://localhost:8008",       "wait": "networkidle"},
    {"name": "mailhog",            "url": "http://localhost:8025",       "wait": "networkidle"},
    {"name": "keycloak",           "url": "http://localhost:8080",       "wait": "networkidle"},
    {"name": "compliance-reporter","url": "http://localhost:8088",       "wait": "networkidle"},
    {"name": "vault",              "url": "http://localhost:8200/ui",    "wait": "networkidle"},
    {"name": "sonarqube",          "url": "http://localhost:9000",       "wait": "networkidle"},
    {"name": "prometheus",         "url": "http://localhost:9090",       "wait": "networkidle"},
    {"name": "alertmanager",       "url": "http://localhost:9093",       "wait": "networkidle"},
    {"name": "opa",                "url": "http://localhost:8181/v1/data","wait": "load"},
]

def capture():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1280, "height": 900})

        for svc in SERVICES:
            page = context.new_page()
            out_path = OUTPUT_DIR / f"{svc['name']}.png"
            try:
                print(f"  Capturing {svc['name']} ({svc['url']}) ...")
                page.goto(svc["url"], wait_until=svc["wait"], timeout=15000)
                page.wait_for_timeout(1500)  # let JS render settle
                page.screenshot(path=str(out_path), full_page=True)
                print(f"  -> saved {out_path.name}")
            except Exception as e:
                print(f"  !! FAILED {svc['name']}: {e}")
            finally:
                page.close()

        context.close()
        browser.close()

if __name__ == "__main__":
    print(f"Saving screenshots to: {OUTPUT_DIR}\n")
    capture()
    print("\nDone.")
