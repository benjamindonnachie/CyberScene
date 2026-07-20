#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
find "$repo_root/scenarios" -name '*.sh' -print0 | xargs -0 -n1 bash -n
python3 - <<'PY' "$repo_root/scenarios/windows/ghosts/config/timeline.json" "$repo_root/scenarios/windows/ghosts/config/application.json" "$repo_root/scenarios/windows/ghosts/admin-config/timeline.json" "$repo_root/scenarios/windows/ghosts/admin-config/application.json" "$repo_root/scenarios/windows/ghosts/admin-config/creds.txt" "$repo_root/scenarios/ecommerce/jmeter/user-journeys.jmx"
import sys
import json
import xml.etree.ElementTree as ET
for path in sys.argv[1:6]:
    with open(path, encoding="utf-8-sig") as stream:
        json.load(stream)
ET.parse(sys.argv[6])
PY
for required in data/windows/activeDirectory_user_pass_only.csv data/windows/ncsc-pwned-passwords-top-1000.txt data/windows/export_data-benign_rdp_20240114-IPs_only_clean_hosts.csv data/windows/export_data-benign_rdp_20240114-IPs_only_clean_gateways.csv data/windows/export_data-malicious_rdp_20240114-IPs_only_clean.csv data/ecommerce/web-shop-users.csv data/ecommerce/Common\ user\ agents.csv data/ecommerce/ecomm_updated_Luhn_minimal_sales-backup_20240113.sql scenarios/ecommerce/site-modifications/README.md scenarios/ecommerce/site-modifications/offline-paypal-random-outcome.patch; do
  test -s "$repo_root/$required"
done
test "$(wc -l < "$repo_root/data/windows/ncsc-pwned-passwords-top-1000.txt" | tr -d ' ')" = 1000
test "$(wc -l < "$repo_root/data/windows/export_data-benign_rdp_20240114-IPs_only_clean_hosts.csv" | tr -d ' ')" = 4666
test "$(wc -l < "$repo_root/data/windows/export_data-benign_rdp_20240114-IPs_only_clean_gateways.csv" | tr -d ' ')" = 4666
test "$(wc -l < "$repo_root/data/windows/export_data-malicious_rdp_20240114-IPs_only_clean.csv" | tr -d ' ')" = 3056
grep -Fq 'CREATE TABLE `users`' "$repo_root/data/ecommerce/ecomm_updated_Luhn_minimal_sales-backup_20240113.sql"
grep -Fq '"HandlerType": "Rdp"' "$repo_root/scenarios/windows/ghosts/admin-config/timeline.json"
grep -Fq '"10.44.0.12|admin"' "$repo_root/scenarios/windows/ghosts/admin-config/timeline.json"
grep -Fq 'if (rand(0, 9) > 0)' "$repo_root/scenarios/ecommerce/site-modifications/offline-paypal-random-outcome.patch"
grep -Fq 'PAYID-FAKE-XQWEDES' "$repo_root/scenarios/ecommerce/site-modifications/offline-paypal-random-outcome.patch"
grep -Fq '<stringProp name="HTTPSampler.path">/sales.php</stringProp>' "$repo_root/scenarios/ecommerce/jmeter/user-journeys.jmx"
echo "Repository validation passed."
