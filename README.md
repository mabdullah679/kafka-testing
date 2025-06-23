short n sweet:

gh repo clone mabdullah679/kafka-testing

cd kafka-testing

chmod +x *.sh

./init-alias.sh

open -a Docker

open -a (your IDE of choice)

./clean-rebuild.sh

wait for "✅ Done. Infra is rebuilding cleanly and starting up."

then:


docker exec -it vm3-app sh

java -jar app.jar --from=beginning

follow CLI prompts and wait for "🧠 Broker ready. Type to broadcast or 'exit' to stop:"

in a new terminal:

docker exec -it vm1-app sh

java -jar app.jar --from=beginning

here, you're looking for:

✅ Connected to Kafka. Topic 'global.chat' is available.
🟢 Connected to Kafka chat. Type your message (or 'exit' to quit):

then in a new terminal:

docker exec -it vm2-app sh

java -jar app.jar --from=beginning


here, you're also looking for:

✅ Connected to Kafka. Topic 'global.chat' is available.
🟢 Connected to Kafka chat. Type your message (or 'exit' to quit):


at this point, you can test e2e messaging which is all managed through Java. 


credits:

Muhammad Abdullah & ChatGPT