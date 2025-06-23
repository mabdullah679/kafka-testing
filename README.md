# Kafka Messaging Test Environment

This project provisions a portable, containerized Kafka test environment with two messaging clients (`vm1-app`, `vm2-app`) and a central broker handler (`vm3-app`). Each app is deployed in an Alpine-based container and communicates via a Kafka topic named `global.chat`.

---

## 🧰 Requirements

* Docker Desktop (or Docker Engine)
* macOS or Linux (Tested on macOS with zsh)

---

## 🚀 Getting Started

### Step 1: Clean Rebuild

Ensure you are in the project root directory. Then run:

```bash
./clean-rebuild.sh
```

This tears down and fully rebuilds all containers, removes metadata files, and starts up the Kafka infrastructure.

### Step 2: Run Kafka Testing Script

👉 You can also run everything in one flow using the alias:

```bash
prov-kafka-test-env
```

Start the testing environment interactively:

```bash
./run-kafka-testing.sh
```

* This script detects whether it’s a fresh deployment
* Waits for `vm3-app` to report Kafka readiness
* Optionally restarts `vm1-app` and `vm2-app` and sends messages
* Prompts for log harvesting afterward

### Step 3: View Messages (Optional)

SSH into `vm3-app` and consume messages:

```bash
docker exec -it kafka-testing-vm3-app sh
kafka-console-consumer --bootstrap-server kafka:9092 --topic global.chat --from-beginning
```

---

## 🧪 Broadcast Test Messages

To re-broadcast from both vm1 and vm2 manually:

```bash
./broadcast-test-msgs.sh
```

Each container will send a structured greeting message to `global.chat`.

---

## 📦 Log Harvesting

Harvest logs and optionally copy them to clipboard:

```bash
./harvest-logs.sh         # Just prints categorized logs
./harvest-logs.sh --copy  # Prints and copies logs
```

---

## 🧼 Clean Project Metadata

To remove macOS-specific metadata, container state, and logs:

```bash
./clean-project.sh
```

---

## 💡 Aliases (Optional)

To enable convenience aliases like:

* `prov-kafka-test-env`
* `clean`
* `sendmsg`

Run:

```bash
./init-alias.sh
```

Then source your shell config:

```bash
source ~/.zshrc
```

---

## 📁 Directory Structure

```
kafka-testing/
├── vm1-app/
│   └── send-msg.sh
├── vm2-app/
│   └── send-msg.sh
├── vm3-app/
│   └── logs/, audit/
├── run-kafka-testing.sh
├── broadcast-test-msgs.sh
├── harvest-logs.sh
├── clean-project.sh
├── clean-rebuild.sh
├── alias-kafka-workflow.sh
└── docker-compose.yml
```

---

## ✅ Outcome

Upon successful setup, `vm1-app` and `vm2-app` will send structured greetings to the Kafka topic `global.chat`, and `vm3-app` will act as both the broker manager and log harvester.

---

For questions or contributions, feel free to fork or reach out!