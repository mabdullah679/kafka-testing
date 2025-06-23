package com.demo.vm3;

import org.apache.kafka.clients.admin.*;
import org.apache.kafka.clients.consumer.*;
import org.apache.kafka.clients.producer.*;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import picocli.CommandLine;
import picocli.CommandLine.Option;

import java.io.FileWriter;
import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.Callable;
import java.lang.management.ManagementFactory;

public class BrokerHandlerApp implements Callable<Integer> {

    @Option(names = "--from", description = "Offset handling: 'beginning' or 'latest'")
    String fromOffset;

    private final String broker = "kafka:9092";
    private final String topic = "global.chat";
    private final String logsDir = "logs";
    private final String auditFile = logsDir + "/audit-" + Instant.now().toEpochMilli() + ".log";

    private KafkaConsumer<String, String> consumer;
    private KafkaProducer<String, String> producer;
    private final String clientId = "broker";

    public static void main(String[] args) {
        int exit = new CommandLine(new BrokerHandlerApp()).execute(args);
        System.exit(exit);
    }

    @Override
    public Integer call() {
        try {
            ensureKafkaAndTopic();

            Properties consumerProps = new Properties();
            consumerProps.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, broker);
            consumerProps.put(ConsumerConfig.GROUP_ID_CONFIG, "broker-consumer");
            consumerProps.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
            consumerProps.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
            consumerProps.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG,
                    "beginning".equalsIgnoreCase(fromOffset) ? "earliest" : "latest");

            consumer = new KafkaConsumer<>(consumerProps);
            consumer.subscribe(Collections.singletonList(topic));

            Properties producerProps = new Properties();
            producerProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, broker);
            producerProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
            producerProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());

            producer = new KafkaProducer<>(producerProps);

            Thread listener = new Thread(this::consumeAndAudit, "BrokerAuditListener");
            listener.start();

            Scanner scanner = new Scanner(System.in);
            System.out.println("🧠 Broker ready. Type to broadcast or 'exit' to stop:");

            while (true) {
                String input = scanner.nextLine().trim();
                if ("exit".equalsIgnoreCase(input)) break;

                String message = String.format("[%s] %s", clientId, input);
                producer.send(new ProducerRecord<>(topic, clientId, message));
            }

            consumer.wakeup();
            listener.join();
            producer.close();
            System.out.println("👋 Broker shutting down.");
            return 0;

        } catch (Exception e) {
            System.out.println("❌ Broker failed to start: " + e.getMessage());
            return 1;
        }
    }

    private void consumeAndAudit() {
        try (FileWriter writer = new FileWriter(auditFile)) {
            while (true) {
                ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(300));
                for (ConsumerRecord<String, String> rec : records) {
                    String entry = String.format("🪵 %s (CPU: %.2f%%, MEM: %.2f MB)\n",
                            rec.value(), getCpuLoad(), getMemoryUsed());
                    System.out.print(entry);
                    writer.write(entry);
                    writer.flush();
                }
            }
        } catch (org.apache.kafka.common.errors.WakeupException ignored) {
        } catch (IOException io) {
            System.out.println("❌ Failed to write audit log: " + io.getMessage());
        } finally {
            consumer.close();
        }
    }

    private void ensureKafkaAndTopic() throws Exception {
        Properties props = new Properties();
        props.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, broker);

        try (AdminClient admin = AdminClient.create(props)) {
            while (true) {
                try {
                    Set<String> topics = admin.listTopics(new ListTopicsOptions().timeoutMs(1000)).names().get();
                    if (topics.contains(topic)) {
                        System.out.println("✅ Topic '" + topic + "' already exists.");
                        break;
                    } else {
                        System.out.print("⚠️  Topic '" + topic + "' not found. Create it now? [Y/n]: ");
                        Scanner scanner = new Scanner(System.in);
                        String input = scanner.nextLine().trim();
                        if (input.equalsIgnoreCase("n")) System.exit(1);

                        System.out.println("📡 Creating topic '" + topic + "'...");
                        NewTopic newTopic = new NewTopic(topic, 1, (short) 1);
                        admin.createTopics(Collections.singleton(newTopic)).all().get();
                        System.out.println("✅ Topic created successfully.");
                        break;
                    }
                } catch (Exception e) {
                    System.out.println("⏳ Still waiting for Kafka broker...");
                    safeSleep(2000);
                }
            }
        }
    }

    private void safeSleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private double getCpuLoad() {
        return ManagementFactory.getOperatingSystemMXBean().getSystemLoadAverage();
    }

    private double getMemoryUsed() {
        long used = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory();
        return used / (1024.0 * 1024);
    }
}