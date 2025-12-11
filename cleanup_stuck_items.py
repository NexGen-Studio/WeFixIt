import json
import requests
from datetime import datetime, timedelta

# Config laden
with open('env.json', 'r') as f:
    env = json.load(f)

SUPABASE_URL = env['SUPABASE_URL']
SUPABASE_KEY = env['SUPABASE_SERVICE_ROLE_KEY']

headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json'
}

print("=" * 50)
print("  HARVESTER CLEANUP")
print("=" * 50)
print()

# Cutoff Zeit (10 Minuten)
cutoff_time = datetime.utcnow() - timedelta(minutes=10)
cutoff_iso = cutoff_time.isoformat() + 'Z'

print(f"Suche Items älter als: {cutoff_time}")
print()

# Hole alle processing Items
print("Lade processing Items...")
url = f"{SUPABASE_URL}/rest/v1/knowledge_harvest_queue?status=eq.processing&select=*"

try:
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    all_items = response.json()
    
    print(f"[OK] {len(all_items)} processing Items geladen")
    
    # Filtere nach Zeit
    stuck_items = [
        item for item in all_items
        if datetime.fromisoformat(item['last_attempt_at'].replace('Z', '+00:00')) < cutoff_time
    ]
    
    print(f"Gefunden: {len(stuck_items)} hängende Items")
    print()
    
    if len(stuck_items) == 0:
        print("[OK] Keine hängenden Items!")
        exit(0)
    
    # Verarbeiten
    reset_count = 0
    failed_count = 0
    
    for item in stuck_items:
        attempts = item.get('attempts', 0)
        max_retries = 3
        
        print("-" * 50)
        print(f"Topic: {item['topic']}")
        print(f"Attempts: {attempts} / {max_retries}")
        
        if attempts >= max_retries:
            # Nach failed_topics
            print("  -> failed_topics")
            
            failed_data = {
                'topic': item['topic'],
                'error_code': 'timeout',
                'error_message': f'Stuck in processing >10min, attempts: {attempts}',
                'retry_count': attempts,
                'status': 'failed'
            }
            
            try:
                # Insert in failed_topics
                r = requests.post(
                    f"{SUPABASE_URL}/rest/v1/failed_topics",
                    headers=headers,
                    json=failed_data
                )
                r.raise_for_status()
                
                # Update queue
                update_data = {
                    'status': 'failed',
                    'error_message': f'Failed after {attempts} attempts'
                }
                r = requests.patch(
                    f"{SUPABASE_URL}/rest/v1/knowledge_harvest_queue?id=eq.{item['id']}",
                    headers=headers,
                    json=update_data
                )
                r.raise_for_status()
                
                print("  [OK] Gespeichert")
                failed_count += 1
            except Exception as e:
                print(f"  [ERROR] {str(e)}")
        else:
            # Zurück auf pending
            print("  -> pending (retry)")
            
            update_data = {
                'status': 'pending',
                'error_message': 'Reset from stuck state'
            }
            
            try:
                r = requests.patch(
                    f"{SUPABASE_URL}/rest/v1/knowledge_harvest_queue?id=eq.{item['id']}",
                    headers=headers,
                    json=update_data
                )
                r.raise_for_status()
                print("  [OK] Zurückgesetzt")
                reset_count += 1
            except Exception as e:
                print(f"  [ERROR] {str(e)}")
    
    print()
    print("=" * 50)
    print("  CLEANUP ABGESCHLOSSEN")
    print("=" * 50)
    print(f"Pending: {reset_count}")
    print(f"Failed: {failed_count}")
    print()

except Exception as e:
    print(f"[ERROR] {str(e)}")
    if hasattr(e, 'response'):
        print(f"Response: {e.response.text}")
    exit(1)
