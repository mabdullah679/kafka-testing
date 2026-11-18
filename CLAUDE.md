# CLAUDE.md

Three Java 21 / Maven console apps (`vm1-app`, `vm2-app` chat clients; `vm3-app` broker handler/auditor) talking over one Kafka topic (`global.chat`) inside Docker Compose (Confluent cp-kafka 7.5.0 + ZooKeeper).
Global working rules: `~/.claude/CLAUDE.md` (not copied here).

## Commands (run and verified)
- Build one app: `cd vm1-app && mvn -B -q package -DskipTests` (same for vm2-app, vm3-app). There are no unit tests.
- Stack: `docker compose build && docker compose up -d`; stop with `docker compose down -v`.
- End-to-end check (stack must be up): `./tests/e2e.sh` (about 10 s when warm, up to 90 s if an old consumer is still in the group). Exit 0 = pass.
- Interactive use: `docker exec -it vm3-app java -jar app.jar --from=beginning`, then the same in `vm1-app` / `vm2-app` (see README).

## Conventions and traps
- Container names are fixed by `container_name` (`vm1-app`, `kafka`, ...), NOT the `kafka-testing-vm1-app` compose default.
- The clients read stdin: automation must pipe stdin and keep it open (see `tests/e2e.sh`). vm3 prompts `Create it now? [Y/n]` only when the topic is missing.
- `run-kafka-testing.sh`, `redeploy.sh` and `broadcast-test-msgs.sh` still assume the old `kafka-testing-vmN-app` names and the Kafka CLI inside vm1/vm2; they do not work against the current compose file. Not fixed in the sanitize pass; do not rely on them.
- `project-structure.txt` and `kafka-project-dump.txt` describe an older layout (e.g. `ProducerApp.java`, different compose); treat as stale.

## Do not touch
- Owner's scripts and the stale dump files without asking; never push to `main` (branch + PR; CI in `.github/workflows/ci.yml`).
