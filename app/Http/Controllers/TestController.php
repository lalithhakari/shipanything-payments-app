<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Redis;
use PhpAmqpLib\Connection\AMQPStreamConnection;
use PhpAmqpLib\Message\AMQPMessage;
use Junges\Kafka\Facades\Kafka;
use Junges\Kafka\Message\Message;

class TestController extends Controller
{
    public function testDbs()
    {
        Cache::put('test_cache', 'This is a test value');
        Redis::set('test_redis', 'This is a test value');

        $dbRow = DB::table('test')->first();

        return response()->json([
            'cacheTest' => Cache::get('test_cache'),
            'redisTest' => Redis::get('test_redis'),
            'dbTest' => $dbRow
        ]);
    }

    public function testRabbitMQ()
    {
        try {
            $host = config('rabbitmq.host');
            $port = config('rabbitmq.port');
            $user = config('rabbitmq.user');
            $password = config('rabbitmq.password');

            // Create connection
            $connection = new AMQPStreamConnection($host, $port, $user, $password);
            $channel = $connection->channel();

            // Declare a queue
            $queueName = 'test_queue';
            $channel->queue_declare($queueName, false, false, false, false);

            // Create a test message
            $messageBody = json_encode([
                'test' => 'RabbitMQ connection successful',
                'timestamp' => now()->toISOString(),
                'service' => 'payments-app'
            ]);

            $message = new AMQPMessage($messageBody, ['content_type' => 'application/json']);

            // Publish message to queue
            $channel->basic_publish($message, '', $queueName);

            // Consume the message to test both publish and consume
            $receivedMessage = null;
            $callback = function ($msg) use (&$receivedMessage, $channel) {
                $receivedMessage = json_decode($msg->body, true);
                $channel->basic_ack($msg->delivery_info['delivery_tag']);
            };

            $channel->basic_consume($queueName, '', false, false, false, false, $callback);

            // Process one message
            $channel->wait(null, false, 2); // Wait max 2 seconds

            // Clean up
            $channel->queue_delete($queueName);
            $channel->close();
            $connection->close();

            return response()->json([
                'status' => 'success',
                'message' => 'RabbitMQ connection and message handling successful',
                'connection_details' => [
                    'host' => $host,
                    'port' => $port,
                    'user' => $user
                ],
                'published_message' => json_decode($messageBody, true),
                'received_message' => $receivedMessage
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'RabbitMQ connection failed',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function testKafka()
    {
        try {
            // Retrieve Kafka brokers from environment variable
            $brokers = env('KAFKA_BROKERS', 'kafka:29092');

            if (empty($brokers)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Kafka brokers are not configured',
                    'note' => 'Ensure KAFKA_BROKERS is set in the environment variables',
                ], 500);
            }

            // Check if rdkafka extension is available
            if (!extension_loaded('rdkafka')) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'rdkafka PHP extension is not loaded',
                    'note' => 'This is required for Kafka functionality',
                ], 500);
            }

            $topicName = 'payments-test-topic';
            $groupId = 'payments-test-consumer-group';

            // Step 1: Producer Test - Create and send a message
            $producerConfig = new \RdKafka\Conf();
            $producerConfig->set('metadata.broker.list', $brokers);
            $producerConfig->set('socket.timeout.ms', '5000');
            $producerConfig->set('message.timeout.ms', '10000');

            $producer = new \RdKafka\Producer($producerConfig);

            // Create a test message
            $messageData = [
                'test' => 'Kafka connection and messaging test',
                'timestamp' => now()->toISOString(),
                'service' => 'payments-app',
                'message_id' => uniqid(),
                'broker' => $brokers,
                'test_type' => 'producer_consumer_test'
            ];

            $publishSuccess = false;
            $publishedMessage = null;

            try {
                // Send a message with raw RdKafka
                $topic = $producer->newTopic($topicName);
                $topic->produce(-1, 0, json_encode($messageData), 'payments-test-key');

                // Poll for events
                $producer->poll(0);

                // Flush with timeout
                $flushResult = $producer->flush(10000); // 10 seconds

                if ($flushResult === 0) {
                    $publishSuccess = true;
                    $publishedMessage = $messageData;
                }
            } catch (\Exception $e) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Kafka producer test failed',
                    'error' => $e->getMessage(),
                    'broker_used' => $brokers,
                    'topic' => $topicName,
                ], 500);
            }

            // Step 2: Consumer Test - Try to consume the message we just sent
            $consumerConfig = new \RdKafka\Conf();
            $consumerConfig->set('metadata.broker.list', $brokers);
            $consumerConfig->set('group.id', $groupId);
            $consumerConfig->set('auto.offset.reset', 'earliest');
            $consumerConfig->set('enable.auto.commit', 'true');
            $consumerConfig->set('auto.commit.interval.ms', '1000');
            $consumerConfig->set('session.timeout.ms', '30000');
            $consumerConfig->set('socket.timeout.ms', '5000');

            $consumer = new \RdKafka\KafkaConsumer($consumerConfig);
            $consumedMessages = [];
            $consumeSuccess = false;

            try {
                // Subscribe to the topic
                $consumer->subscribe([$topicName]);

                // Try to consume messages for a limited time
                $startTime = time();
                $timeout = 15; // 15 seconds timeout
                $maxMessages = 5; // Maximum messages to consume

                while (time() - $startTime < $timeout && count($consumedMessages) < $maxMessages) {
                    $message = $consumer->consume(2000); // 2 second timeout per consume call

                    if ($message === null) {
                        continue;
                    }

                    switch ($message->err) {
                        case RD_KAFKA_RESP_ERR_NO_ERROR:
                            $messageContent = json_decode($message->payload, true);
                            $consumedMessages[] = [
                                'partition' => $message->partition,
                                'offset' => $message->offset,
                                'key' => $message->key,
                                'payload' => $messageContent,
                                'timestamp' => $message->timestamp,
                                'consumed_at' => now()->toISOString()
                            ];
                            $consumeSuccess = true;
                            break;

                        case RD_KAFKA_RESP_ERR__PARTITION_EOF:
                            // End of partition - this is normal
                            break;

                        case RD_KAFKA_RESP_ERR__TIMED_OUT:
                            // Timeout - this is normal when no messages are available
                            break;

                        default:
                            // Log other errors but continue
                            break;
                    }
                }

                $consumer->close();
            } catch (\Exception $e) {
                return response()->json([
                    'status' => 'partial_success',
                    'message' => 'Kafka producer worked but consumer test failed',
                    'producer_result' => [
                        'success' => $publishSuccess,
                        'published_message' => $publishedMessage
                    ],
                    'consumer_error' => $e->getMessage(),
                    'broker_used' => $brokers,
                    'topic' => $topicName,
                    'group_id' => $groupId,
                ], 200);
            }

            // Step 3: Return comprehensive results
            if ($publishSuccess && $consumeSuccess) {
                return response()->json([
                    'status' => 'success',
                    'message' => 'Kafka producer and consumer test successful',
                    'broker_used' => $brokers,
                    'topic' => $topicName,
                    'group_id' => $groupId,
                    'producer_result' => [
                        'success' => true,
                        'published_message' => $publishedMessage,
                        'flush_result' => 'success'
                    ],
                    'consumer_result' => [
                        'success' => true,
                        'messages_consumed' => count($consumedMessages),
                        'consumed_messages' => $consumedMessages,
                        'timeout_used' => $timeout . ' seconds'
                    ],
                    'test_summary' => [
                        'total_messages_published' => 1,
                        'total_messages_consumed' => count($consumedMessages),
                        'round_trip_test' => 'passed'
                    ]
                ]);
            } elseif ($publishSuccess && !$consumeSuccess) {
                return response()->json([
                    'status' => 'partial_success',
                    'message' => 'Kafka producer successful, but no messages were consumed (this may be normal)',
                    'broker_used' => $brokers,
                    'topic' => $topicName,
                    'group_id' => $groupId,
                    'producer_result' => [
                        'success' => true,
                        'published_message' => $publishedMessage
                    ],
                    'consumer_result' => [
                        'success' => false,
                        'messages_consumed' => 0,
                        'note' => 'No messages were available for consumption within the timeout period'
                    ],
                    'possible_reasons' => [
                        'Message may have been consumed by another consumer',
                        'Consumer group may have different offset settings',
                        'Topic may not have retained the message',
                        'Timing issue between producer and consumer'
                    ]
                ]);
            } else {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Kafka producer failed',
                    'broker_used' => $brokers,
                    'topic' => $topicName,
                    'producer_result' => [
                        'success' => false,
                        'note' => 'Message publishing failed or timed out'
                    ]
                ], 500);
            }
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Kafka test failed',
                'error' => $e->getMessage(),
                'broker_attempted' => $brokers ?? 'N/A',
                'rdkafka_loaded' => extension_loaded('rdkafka')
            ], 500);
        }
    }

    public function testMicroserviceConnection()
    {
        $res = Http::get('http://auth.shipanything.test');
        return $res->body();
    }
}
