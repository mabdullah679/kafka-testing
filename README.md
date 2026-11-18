# kafka-testing

Three Java console apps that chat through one Kafka topic inside Docker Compose: two chat clients (`vm1-app`, `vm2-app`) and a broker handler (`vm3-app`) that creates the topic, broadcasts, and writes an audit log.

```
 vm1-app --\                         /--> vm1-app / vm2-app print 📩 messages
            >--> kafka:9092 (topic global.chat) --> vm3-app writes /app/logs/audit-*.log
 vm2-app --/        |
                zookeeper:2181
```

Not local: the Confluent Kafka/ZooKeeper images and the Maven/Temurin base images are pulled from Docker Hub; Maven downloads dependencies during the image build.

## Prerequisites
- Docker with `docker compose`, running. Nothing else on the host (Java and Maven run inside the build containers).
- Port 9092 free (published by the `kafka` service). Optional for local builds outside Docker: JDK 21 and Maven.

## Run it
1. `docker compose build && docker compose up -d` (or `./clean-rebuild.sh`, which tears down, deletes `._*` files and rebuilds with `--no-cache`)
2. Broker handler: `docker exec -it vm3-app sh`, then `java -jar app.jar --from=beginning`. Answer `Y` to the topic prompt if it appears; wait for `🧠 Broker ready. Type to broadcast or 'exit' to stop:`
3. New terminal: `docker exec -it vm1-app sh`, then `java -jar app.jar --from=beginning`. Wait for `🟢 Connected to Kafka chat. Type your message (or 'exit' to quit):`
4. Another terminal: the same for `vm2-app`.
5. Type in any of the three; the others print it. `exit` quits a client. `docker compose down -v` tears everything down.

If a client says `Kafka or topic not available yet. Retry or exit? [r/exit]`, the broker or topic is not ready: start `vm3-app` first (it creates `global.chat`) and answer `r`. If port 9092 is taken, change the left side of `"9092:9092"` in `docker-compose.yml`; the apps talk to `kafka:9092` on the Compose network and are unaffected.

## What it does
| Action | Result |
|---|---|
| `vm3-app` starts | waits for Kafka, creates `global.chat` (1 partition, replication 1) on confirmation, prints `Broker ready` |
| line typed in `vm1-app` / `vm2-app` / `vm3-app` | produced as `[clientId] text`; every running client prints it with 📩, `vm3-app` prints it with 🪵 and CPU/memory |
| `vm3-app` running | appends each message to `/app/logs/audit-<epoch-ms>.log` (shared volume `kafka-audit-logs`; mounted read-only in vm1/vm2) |
| `--from=beginning` | consumer starts at `earliest` when the group has no committed offset (otherwise `latest`) |

## Interface
| Command | Where | Notes |
|---|---|---|
| `java -jar app.jar [--from=beginning]` | each app container | picocli option; reads stdin; `exit` quits |
| `kafka:9092` | Compose network / host `localhost:9092` | advertised listener is `kafka:9092`, so host clients cannot connect directly |

## Tests
There are no unit tests. `./tests/e2e.sh` (stack up first) pipes input into the three real apps: vm3 creates the topic, vm2 listens, vm1 sends a unique marker, and the script passes only if vm2 receives it and vm3's audit log file contains it. It needs Docker and the running stack, no external services. CI (`.github/workflows/ci.yml`) also compiles all three apps with JDK 21, validates the compose file, runs shellcheck (errors only) and gitleaks.

## Layout
| Path | Role |
|---|---|
| [docker-compose.yml](docker-compose.yml) | Kafka, ZooKeeper and the three app containers |
| [vm1-app/](vm1-app/), [vm2-app/](vm2-app/) | chat clients ([source](vm1-app/src/main/java/com/demo/vm1/ChatClientApp.java)) |
| [vm3-app/](vm3-app/) | broker handler and audit logger ([source](vm3-app/src/main/java/com/demo/vm3/BrokerHandlerApp.java)) |
| [tests/e2e.sh](tests/e2e.sh) | end-to-end check |
| [clean-rebuild.sh](clean-rebuild.sh), [clean-project.sh](clean-project.sh), [init-alias.sh](init-alias.sh) | owner helper scripts (`init-alias.sh` appends aliases to your `~/.zshrc` / `~/.bashrc`) |
| [.github/workflows/ci.yml](.github/workflows/ci.yml) | CI |
| [CLAUDE.md](CLAUDE.md) | notes for Claude Code sessions |

## Known issues (not fixed in this pass)
- [run-kafka-testing.sh](run-kafka-testing.sh), [redeploy.sh](redeploy.sh) and [broadcast-test-msgs.sh](broadcast-test-msgs.sh) look for containers named `kafka-testing-vmN-app`, but `docker-compose.yml` names them `vmN-app`; `broadcast-test-msgs.sh` prints `No target containers (vm1/vm2) found` against a running stack. The `send-msg.sh` helpers also need `kafka-console-producer.sh`, which the vm1/vm2 images do not contain.
- [project-structure.txt](project-structure.txt) and [kafka-project-dump.txt](kafka-project-dump.txt) describe an older layout and are stale.

## Design notes
- Each app is a fat JAR (maven-assembly-plugin) built in a multi-stage Dockerfile, so the host needs no JDK. Alternative: mount the source and build at run time, which would slow every start.
- The apps are interactive on purpose (stdin chat), so automation has to keep stdin open; `tests/e2e.sh` does that with a subshell `sleep`.
- ZooKeeper-based Kafka (cp-kafka 7.5.0) is used as-is; it is a single broker with replication factor 1, for demonstration, not durability.

## Credits
Muhammad Abdullah & ChatGPT
