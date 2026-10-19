#!/usr/bin/env python3
"""
SafeTour: Seeding script for Supabase public.safety_zones table.
Reads from Scores.csv and upserts to Supabase using the Service Role Key.
Credentials are automatically loaded from .env or system environment variables.
"""
import os
import sys
import csv
import json
import urllib.request
import urllib.error

# Load .env file automatically if present
env_file = os.path.join(os.path.dirname(__file__), ".env")
if os.path.exists(env_file):
    with open(env_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://egvfpjasmojxuataajeb.supabase.co")
SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

CSV_PATH = os.path.join(os.path.dirname(__file__), "Scores.csv")

def seed():
    if not SERVICE_KEY:
        print("Error: SUPABASE_SERVICE_ROLE_KEY is not set.")
        print("Please copy .env.example to .env and configure your SUPABASE_SERVICE_ROLE_KEY, or set it in your environment.")
        sys.exit(1)

    url = f"{SUPABASE_URL}/rest/v1/safety_zones"
    headers = {
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }

    rows = []
    with open(CSV_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append({
                "area_name": r["area_name"],
                "latitude": float(r["latitude"]),
                "longitude": float(r["longitude"]),
                "radius_meters": int(r["radius_meters"]),
                "day_score": float(r["day_score"]),
                "night_score": float(r["night_score"]),
                "overall_score": float(r["overall_score"]),
                "crowd_rating": int(r["crowd_rating"]),
                "lighting_rating": int(r["lighting_rating"]),
                "safety_tips": r["safety_tips"]
            })

    req = urllib.request.Request(
        url,
        data=json.dumps(rows).encode("utf-8"),
        headers=headers,
        method="POST"
    )

    try:
        with urllib.request.urlopen(req) as resp:
            print(f"Successfully seeded {len(rows)} safety zones into Supabase! (HTTP {resp.status})")
            return True
    except urllib.error.HTTPError as e:
        err_body = e.read().decode()
        print(f"Failed to seed safety zones: HTTP {e.code} - {err_body}")
        if "PGRST205" in err_body:
            print("Notice: The 'public.safety_zones' table does not exist in the database yet.")
            print("Please run the schema migration script (supabase/migrations/20260913_initial_schema.sql) in the Supabase SQL Editor first.")
        return False
    except Exception as e:
        print(f"Unexpected error: {e}")
        return False

if __name__ == "__main__":
    seed()
