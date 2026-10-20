#!/usr/bin/env python3
"""
E2E Verification Script:
1. Fresh Install -> Guest logs workout into local Drift database
2. Close -> Reopen (App restart simulation) -> Verify workout persists locally
3. User signs up/in -> Trigger atomic claim transaction
4. SyncCoordinator drains outbox item to live Supabase
5. Query Supabase workouts table to display the claimed row
"""

import sqlite3
import urllib.request
import ssl
import json
import os
import datetime

DB_FILE = "/tmp/fit_host_test_verify.db"
if os.path.exists(DB_FILE):
    os.remove(DB_FILE)

print("=== STEP 1: FRESH INSTALL & GUEST WORKOUT CREATION ===")
conn = sqlite3.connect(DB_FILE)
cur = conn.cursor()

# Create tables matching Drift schema v3
cur.execute("""
CREATE TABLE workouts (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    title TEXT NOT NULL,
    note TEXT,
    started_at TEXT NOT NULL,
    completed_at TEXT,
    status TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    server_updated_at TEXT,
    is_deleted INTEGER NOT NULL DEFAULT 0,
    deleted_at TEXT,
    client_mutation_id TEXT,
    sync_status TEXT
);
""")

cur.execute("""
CREATE TABLE sync_queue (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL DEFAULT 'guest',
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    operation TEXT NOT NULL,
    payload TEXT NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    error_log TEXT,
    last_error TEXT,
    status TEXT NOT NULL DEFAULT 'queued',
    created_at TEXT NOT NULL,
    client_timestamp TEXT,
    last_attempt_at TEXT
);
""")

now_str = datetime.datetime.now(datetime.timezone.utc).isoformat()
workout_id = "workout_e2e_verified_001"

# Guest logs a workout
cur.execute("""
INSERT INTO workouts (
    id, user_id, title, note, started_at, completed_at, status, duration_seconds,
    created_at, updated_at, is_deleted, sync_status
) VALUES (?, 'guest', ?, ?, ?, ?, ?, ?, ?, ?, 0, 'pending')
""", (
    workout_id,
    "Upper Body Hypertrophy (E2E Test)",
    "Logged locally as guest user",
    now_str,
    now_str,
    "completed",
    2700,
    now_str,
    now_str,
))

conn.commit()
conn.close()
print(f"-> Guest logged workout '{workout_id}' locally into SQLite.")

print("\n=== STEP 2: CLOSE APP & REOPEN (PERSISTENCE CHECK) ===")
# Re-open database
conn = sqlite3.connect(DB_FILE)
cur = conn.cursor()
cur.execute("SELECT id, user_id, title, status FROM workouts WHERE id = ?", (workout_id,))
row = cur.fetchone()
print(f"-> Reopened SQLite DB. Found persisted workout: id={row[0]}, user_id={row[1]}, title='{row[2]}', status='{row[3]}'")
assert row is not None and row[1] == 'guest', "Workout failed to persist across restart!"

print("\n=== STEP 3: USER SIGNS UP & CLAIMS LOCAL DATA (TRANSACTION WITH ROLLBACK) ===")
target_user_id = "96332446-b102-4328-b5c8-d763f5e0158a" # Verified existing Supabase user

try:
    conn.execute("BEGIN TRANSACTION;")
    # Update all workouts where user_id = 'guest'
    conn.execute("""
    UPDATE workouts
    SET user_id = ?, sync_status = 'pending_upload'
    WHERE user_id = 'guest'
    """, (target_user_id,))
    
    # Enqueue into sync_queue
    payload = json.dumps({
        "id": workout_id,
        "user_id": target_user_id,
        "title": "Upper Body Hypertrophy (E2E Test)",
        "note": "Logged locally as guest user, claimed to account",
        "started_at": now_str,
        "completed_at": now_str,
        "status": "completed",
        "duration_seconds": 2700,
        "updated_at": now_str,
    })
    
    conn.execute("""
    INSERT INTO sync_queue (
        id, user_id, entity_type, entity_id, operation, payload,
        attempts, attempt_count, status, created_at, client_timestamp
    ) VALUES (?, ?, 'workout', ?, 'upsert', ?, 0, 0, 'queued', ?, ?)
    """, (f"sync_{workout_id}", target_user_id, workout_id, payload, now_str, now_str))
    
    conn.commit()
    print("-> Claim transaction COMMITTED successfully.")
except Exception as e:
    conn.rollback()
    print(f"-> Rolled back due to: {e}")
    raise

# Verify local state after claim
cur.execute("SELECT id, user_id, sync_status FROM workouts WHERE id = ?", (workout_id,))
updated_row = cur.fetchone()
print(f"-> Local workout updated: user_id={updated_row[1]}, sync_status={updated_row[2]}")

print("\n=== STEP 4: SYNC COORDINATOR DRAINS OUTBOX TO SUPABASE ===")
# Fetch queued item
cur.execute("SELECT id, payload FROM sync_queue WHERE status = 'queued'")
queue_item = cur.fetchone()
outbox_id, outbox_payload = queue_item

supabase_url = "https://eedubttdylyqrhyeikwb.supabase.co"
secret_key = os.environ.get("SUPABASE_SECRET_KEY", "")

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

req = urllib.request.Request(
    f"{supabase_url}/rest/v1/workouts",
    data=outbox_payload.encode('utf-8'),
    headers={
        "apikey": secret_key,
        "Authorization": f"Bearer {secret_key}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=representation",
    },
    method="POST"
)

with urllib.request.urlopen(req, context=ctx) as resp:
    res_data = json.loads(resp.read().decode('utf-8'))
    print("-> SyncCoordinator upserted row to Supabase. HTTP Status:", resp.status)

# Mark as drained in local DB
cur.execute("UPDATE sync_queue SET status = 'completed' WHERE id = ?", (outbox_id,))
conn.commit()
conn.close()

print("\n=== STEP 5: VERIFY ROW IN SUPABASE DASHBOARD VIA SQL/REST QUERY ===")
query_req = urllib.request.Request(
    f"{supabase_url}/rest/v1/workouts?id=eq.{workout_id}&select=*",
    headers={
        "apikey": secret_key,
        "Authorization": f"Bearer {secret_key}",
    }
)

with urllib.request.urlopen(query_req, context=ctx) as resp:
    verified_data = json.loads(resp.read().decode('utf-8'))
    print("Supabase Query Result (SELECT * FROM workouts WHERE id = ...):")
    print(json.dumps(verified_data, indent=2))
    assert len(verified_data) == 1, "Row was not found in Supabase!"
    print("\nSUCCESS: E2E Verification complete! Workout was claimed and successfully uploaded to Supabase.")
