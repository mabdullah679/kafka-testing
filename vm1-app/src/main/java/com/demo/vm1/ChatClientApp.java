package com.demo.vm1;

// (Identical imports as vm2)
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.ListTopicsOptions;
import org.apache.kafka.clients.admin.ListTopicsResult;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import picocli.CommandLine;
import picocli.CommandLine.Option;

import java.time.Duration;
import java.util.*;
import java.util.concurrent.Callable;

public class ChatClientApp implements Callable<Integer> {

    @Option(names = "--from", description = "Message offset behavior (e.g., 'beginning')")
    String fromOffset;

    private final String broker = "kafka:9092";;
    private final String topic = "global.chat";
    private KafkaConsumer<String, String> consumer;
    private KafkaProducer<String, String> producer;
    private String clientId;

    public static void main(String[] args) {
        int exitCode = new CommandLine(new ChatClientApp()).execute(args);
        System.exit(exitCode);
    }

    @Override
    public Integer call() {
        this.clientId = System.getenv().getOrDefault("CLIENT_ID", UUID.randomUUID().toString());

        waitForKafkaAndTopic();

        Properties consumerProps = new Properties();
        consumerProps.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, broker);
        consumerProps.put(ConsumerConfig.GROUP_ID_CONFIG, "vm1-client-group");
        consumerProps.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        consumerProps.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        consumerProps.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG,
                "beginning".equalsIgnoreCase(fromOffset) ? "earliest" : "latest");

        consumer = new KafkaConsumer<>(consumerProps);
        consumer.subscribe(Collections.singletonList(topic));

        Properties producerProps = new Properties();
        producerProps.put("bootstrap.servers", broker);
        producerProps.put("key.serializer", StringSerializer.class.getName());
        producerProps.put("value.serializer", StringSerializer.class.getName());

        producer = new KafkaProducer<>(producerProps);

        Thread listenerThread = new Thread(this::listenForMessages, "ConsumerThread");
        listenerThread.start();

        Scanner scanner = new Scanner(System.in);
        System.out.println("🟢 Connected to Kafka chat. Type your message (or 'exit' to quit):");

        while (true) {
            String input = scanner.nextLine().trim();
            if (input.equalsIgnoreCase("exit")) break;

            String message = String.format("[%s] %s", clientId, input);
            producer.send(new ProducerRecord<>(topic, clientId, message));
        }

        consumer.wakeup();
        try {
            listenerThread.join();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            System.out.println("⚠️ Interrupted while closing consumer.");
        }
        producer.close();
        System.out.println("👋 Disconnected from chat.");
        return 0;
    }

    private void listenForMessages() {
        try {
            while (true) {
                ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(300));
                records.forEach(record -> System.out.println("📩 " + record.value()));
            }
        } catch (org.apache.kafka.common.errors.WakeupException ignored) {
        } finally {
            consumer.close();
        }
    }

    private void waitForKafkaAndTopic() {
        Properties adminProps = new Properties();
        adminProps.put("bootstrap.servers", broker);

        try (AdminClient admin = AdminClient.create(adminProps)) {
            boolean firstTry = true;
            boolean connected = false;

            while (!connected) {
                try {
                    ListTopicsResult result = admin.listTopics(new ListTopicsOptions().timeoutMs(1000));
                    Set<String> topics = result.names().get();

                    if (topics.contains(topic)) {
                        System.out.println("✅ Connected to Kafka. Topic '" + topic + "' is available.");
                        connected = true;
                    } else {
                        throw new RuntimeException("Topic not found.");
                    }
                } catch (Exception e) {
                    if (firstTry) {
                        System.out.println("⏳ Kafka or topic not available yet. Retry or exit? [r/exit]");
                        Scanner scanner = new Scanner(System.in);
                        String choice = scanner.nextLine().trim();
                        if (choice.equalsIgnoreCase("exit")) {
                            System.exit(1);
                        }
                        firstTry = false;
                    } else {
                        System.out.println("🔁 Still waiting on Kafka broker/topic...");
                        safeSleep(1500);
                    }
                }
            }
        }
    }

    private void safeSleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            System.out.println("⚠️ Sleep interrupted.");
        }
    }
}