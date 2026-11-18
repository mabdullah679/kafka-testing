KAFKA-TESTING (plain-text version of README.md)

What it is
Three small Java chat programs that talk to each other through Kafka (a message bus) on your own computer using Docker Compose. Two are chat clients (vm1-app and vm2-app). The third (vm3-app) sets up the chat channel, can broadcast too, and keeps an audit log of every message.

How it fits together
All three connect to one Kafka server, on a channel (topic) named global.chat. Anything typed in one program shows up in the others. vm3-app also writes each message to a log file. Not on your computer: the Docker images (Kafka, ZooKeeper, Java, Maven) and the Java libraries are downloaded when you build.

What you need
Docker running with compose. Port 9092 free. Nothing else; Java and Maven run inside Docker.

How to run it
1. Run: docker compose build && docker compose up -d (or ./clean-rebuild.sh, which wipes and rebuilds everything).
2. Run: docker exec -it vm3-app sh, then: java -jar app.jar --from=beginning. If it asks to create the topic, answer Y. Wait for the line "Broker ready".
3. In a second terminal: docker exec -it vm1-app sh, then: java -jar app.jar --from=beginning. Wait for the line "Connected to Kafka chat".
4. In a third terminal do the same for vm2-app.
5. Type a message in any of them and the others show it. Type exit to leave. Run docker compose down -v to shut everything down.

If something goes wrong
If a client asks "Retry or exit?", Kafka or the topic is not ready. Start vm3-app first, then answer r. If port 9092 is taken, change the left number in "9092:9092" in docker-compose.yml.

What it does
vm3-app waits for Kafka and creates the channel (one partition, one copy). Each typed line is sent as "[client id] text". Every client shows it with an envelope icon; vm3-app shows it with CPU and memory figures and appends it to a file named audit-(time).log in the shared volume. The option --from=beginning means start from the oldest message when the program has no saved position yet; otherwise it starts from the newest.

Commands
java -jar app.jar [--from=beginning] runs inside each app container, reads what you type, and exit quits. Kafka is at kafka:9092 inside Docker. From your own computer you cannot connect to it directly because it advertises that inside-Docker name.

Tests
There are no unit tests. The script tests/e2e.sh (start the stack first) drives the three real programs: vm3 creates the channel, vm2 listens, vm1 sends a unique code word, and the script passes only if vm2 receives it and the audit file written by vm3 contains it. It needs only Docker. The automatic check on GitHub also compiles all three programs with Java 21, validates the compose file, runs shellcheck for errors, scans for leaked secrets, and runs that same end-to-end script.

Files
docker-compose.yml defines everything. vm1-app and vm2-app are the clients. vm3-app is the broker handler. tests/e2e.sh is the end-to-end check. clean-rebuild.sh, clean-project.sh and init-alias.sh are the owner's helper scripts (init-alias.sh adds shortcuts to your shell startup file). .github/workflows/ci.yml is the automatic check. CLAUDE.md is notes for Claude Code.

Known problems, not fixed in this pass
run-kafka-testing.sh, redeploy.sh and broadcast-test-msgs.sh look for containers called kafka-testing-vm1-app and so on, but the compose file names them vm1-app and so on, so broadcast-test-msgs.sh says it cannot find the containers while the stack is running. The send-msg.sh helpers also need a Kafka command-line tool that the vm1 and vm2 images do not contain. project-structure.txt and kafka-project-dump.txt describe an older layout and are out of date.

Design notes
Each program is built into one runnable JAR inside Docker, so you need no Java on your computer. The programs are interactive on purpose, so automation has to keep their input open, which tests/e2e.sh does. Kafka runs as a single server with one copy of the data, which is fine for a demo but not for durability.

Credits
Muhammad Abdullah and ChatGPT.
