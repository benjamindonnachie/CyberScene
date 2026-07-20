# Synthetic small-office and e-commerce simulations

Reproducibility materials for two isolated VirtualBox scenarios used to generate realistic synthetic incident-response and forensic datasets:

1. a compromised Windows Server 2022 in a simulated small-office network;
2. a defaced Ubuntu 22.04 e-commerce web server.

## Shared simulation design

Both scenarios combine routine user behaviour, background Internet noise and researcher-controlled attacker activity. The environments ran as isolated VirtualBox networks while using selected real-world public IP addresses as simulated source identities inside the laboratory.

All people, user accounts, credentials, contact details, payment-card values and transaction records in this repository are entirely synthetic and were created using [GenerateData.com](https://generatedata.com/). They do not describe real individuals or customers. The network-address fixtures are different: they contain historical Internet-scanner intelligence and IP-geolocation data used to reproduce plausible source identities.

Routine background scanning was modelled by selecting public scanner identities derived from [GreyNoise](https://www.greynoise.io/) data and running Nmap inside the controlled networks. The researcher performed most attacker activity manually, choosing and controlling the intrusion steps and tools. Automation was limited to bounded operations such as password attempts, background scanning and individual web-assessment tools; neither scenario used an autonomous end-to-end attacker.

## Safety and initial setup

Run these materials only in an isolated, authorised laboratory. Scripts that change VM state, add IP addresses or launch scanners default to dry-run. Pass `--execute` only after checking the printed interface and target. Public IPs in the fixtures must not be used to scan public systems.

Create the local configuration and validate the repository before running either scenario:

```bash
cp config/simulation.env.example .env
set -a; source .env; set +a
./tests/validate.sh
```

Host-specific paths from the original laboratory are intentionally retained where they document the setup. Override configurable paths and targets in `.env` when reproducing it elsewhere.

## Windows small-office scenario

### Environment

The Windows scenario represents a small office built around a central Windows Server 2022. Windows 10 clients logged in as randomly selected synthetic domain users and generated ordinary workstation and server activity. A separate work-from-home administrator client connected through the external `adminwfh` network. The resulting dataset represents a server compromised amid routine user, administrative and background-scanning traffic.

### Ordinary user activity

The lifecycle script signs each Windows client in as a randomly selected synthetic domain user before [CMU SEI GHOSTS](https://cmu-sei.github.io/GHOSTS/) takes over the session. The recovered user timeline lists files on the central `\\file-server\reports` share, creates Word, Excel and PowerPoint documents with PDF exports, manages downloaded files, browses varied websites in Firefox, and posts to a configured blog using Chrome. Its looping handlers and pauses generate endpoint artefacts, file-server access and web traffic under different user identities.

The ordinary-client configuration is under `scenarios/windows/ghosts/config/`. GHOSTS v7 is not bundled; install it separately under its own licence and place the recovered `timeline.json` and `application.json` in the client configuration directory.

### Administrator work-from-home activity

The final February 2024 `Win10-Ghosts-0` VM used the separate configuration under `scenarios/windows/ghosts/admin-config/`. Its timeline contains an `Rdp` handler active from 08:45 to 17:15, selects the `admin` entry from `C:\creds.txt`, and connects to the simulated Windows Server. The password field is Base64-encoded rather than encrypted and decodes to the synthetic administrator password used in the simulation.

For reproduction, use this configuration instead of the ordinary-client timeline and place `creds.txt` at `C:\creds.txt`. The runnable copies remove one trailing comma from the recovered timeline and credential file so they are strict JSON; byte-for-byte recovered files are preserved under `archive/original/windows/ghosts-admin/`.

### Scanning and attacker activity

The Windows Nmap wrapper selects a paired host and gateway identity from the retained GreyNoise-derived RDP-scanner CSVs and scans the server's RDP service on TCP/3389. It expects the selected host address to have already been loaded as an alias on the isolated scanner VM's `eth0`, as it was in the original laboratory. Override its paths, target or interface with the `WINDOWS_SCAN_*` settings in `.env`.

The RDP password attempts used `data/windows/ncsc-pwned-passwords-top-1000.txt`, the first 1,000 entries from the NCSC `PwnedPasswordsTop100k` artefact retained on the simulation host. Researcher records state that Hydra was run manually first and the attempts were switched to Crowbar on 4 February 2024. Server logs corroborate the automated attempt stream and switch time but do not identify the remote client executable, so the tool names come from the scenario record rather than host-forensic identification. The password list is included as a reproduction artefact, not a password recommendation.

Run the Windows lifecycle and background scanner in dry-run mode with:

```bash
./scenarios/windows/scripts/vm-session-cycle.sh start
./scenarios/windows/scripts/run-nmap-simulation.sh
```

## Ubuntu e-commerce scenario

### Environment and application

The Ubuntu 22.04 scenario represents a public e-commerce site receiving customer traffic, routine Internet scanning and a mostly manual attack that culminated in defacement. The shop was based on [e-Commerce Site using PHP/PDO, PHPMailer, ReCaptcha, and PayPal](https://www.sourcecodester.com/php/12287/e-commerce-site-using-php-pdo.html), submitted by `nurhodelta_17` and mirrored by [`oretnom23/PHP-eCommerce-Site`](https://github.com/oretnom23/PHP-eCommerce-Site). [Damn Vulnerable Web Application (DVWA)](https://github.com/digininja/DVWA) was later added as the deliberately vulnerable component used to introduce controlled web-application weaknesses.

### Customer activity and load cycle

The [Apache JMeter](https://jmeter.apache.org/) plan does not replay one fixed or identical request sequence for every customer. On each loop, its Random Controller selects one activity from the available home-page, login, account, category, product, cart, checkout and logout actions; each virtual customer repeats that random selection between one and eighteen times. Extracted category and product identifiers, a variable cart quantity, and the random checkout outcome add further variation within those paths. Each customer also receives a randomly selected synthetic account, UK source address and user agent, retains its own cookies, and pauses for approximately three to six seconds between requests.

Its seven-row Ultimate Thread Group varies the number of users, ramp-up, sustained load and ramp-down across the daily and weekly cycle. The plan records a 03:00 alignment, with sequence day zero beginning on Wednesday and the first displayed row corresponding to Thursday. Start it at the same weekday and time when reproducing the original dataset rather than treating it as a short, flat load test.

The plan requires JMeter 5.6.3 plus the JMeter Plugins Random CSV Data Set and Custom Thread Groups components. Run it from the repository root with:

```bash
./scenarios/ecommerce/scripts/run-jmeter.sh
```

### Offline checkout modification

The shop's checkout handler was modified so customer journeys did not require PayPal connectivity. The retained `sales.php` condition produces a 90% local success path, which records the sale with a fake payment ID, and a 10% failure path, which records no sale and leaves the cart unchanged. Neither path contacts PayPal, and the JMeter checkout journey calls `/sales.php` directly.

Apply `scenarios/ecommerce/site-modifications/offline-paypal-random-outcome.patch` to the credited upstream shop to reproduce this behaviour. The accompanying README documents the exact change and upstream commit used for comparison.

### Synthetic customer database

The complete MariaDB dump is `data/ecommerce/ecomm_updated_Luhn_minimal_sales-backup_20240113.sql`. It contains the application schema, products, sales and 1,003 user records: 1,000 GenerateData.com accounts used by JMeter plus three original synthetic application accounts.

Import it with a MariaDB-compatible client, for example:

```bash
mysql -u root -p < data/ecommerce/ecomm_updated_Luhn_minimal_sales-backup_20240113.sql
```

### Scanning and attacker activity

The e-commerce Nmap wrapper selects a retained scanner identity for routine background traffic. The web-scanning wrapper covers Nikto, Skipfish and WhatWeb. These wrappers default to printing their commands without executing them; the scenario's wider attacker activity was controlled manually by the researcher.

Run the scanners in dry-run mode with:

```bash
./scenarios/ecommerce/scripts/run-nmap-simulation.sh
./scenarios/ecommerce/scripts/run-web-scans.sh
```

## Completed datasets

- [Compromised Windows Server 2022 (simulation)](https://ordo.open.ac.uk/articles/dataset/Compromised_Windows_Server_2022_simulation_/26038642)
- [Defaced web server Ubuntu 22.04 (simulation)](https://ordo.open.ac.uk/articles/dataset/Defaced_web_server_Ubuntu_22_04_simulation_/26038669)

Both datasets were published through The Open University Research Data Online repository and are licensed CC BY-NC-SA 4.0.

See [artifact provenance](docs/provenance.md) for reconstruction details, source hashes and distinctions between recovered originals and cleaned reproduction files.

## Acknowledgements and data sources

- OpenAI Codex assisted with preparing this repository: collating and organising retained files, documenting provenance, adding validation, and reconstructing missing convenience wrappers from the recorded setup. Codex did not create the original simulation artefacts, synthetic source data, research scenarios, forensic datasets or published datasets; those pre-date this repository-preparation work.
- OpenWolf provided context management during repository preparation, reducing repeated context loading and associated token usage. It did not create the original research or simulation artefacts.
- [GenerateData.com](https://generatedata.com/) was used to create the synthetic personal, account, contact, payment and transaction records.
- [GreyNoise](https://www.greynoise.io/) supplied the historical Internet-scanner intelligence from which scanner source identities were selected for controlled laboratory traffic.
- The UK National Cyber Security Centre supplied the retained `PwnedPasswordsTop100k` source artefact; this repository includes the 1,000-entry subset used by the RDP password-attempt simulation.
- [CMU SEI GHOSTS](https://cmu-sei.github.io/GHOSTS/) and [Apache JMeter](https://jmeter.apache.org/) generated benign user activity in the Windows and e-commerce scenarios respectively.
- The e-commerce environment used [nurhodelta_17's PHP/PDO e-Commerce Site](https://www.sourcecodester.com/php/12287/e-commerce-site-using-php-pdo.html) as its base shop and [Damn Vulnerable Web Application](https://github.com/digininja/DVWA) by the DVWA contributors as its intentionally vulnerable training component.
