<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Default Kafka Connection Name
    |--------------------------------------------------------------------------
    |
    | Here you may specify which of the Kafka connections below you wish
    | to use as your default connection for all Kafka work.
    |
    */

    'default' => env('KAFKA_CONNECTION', 'default'),

    /*
    |--------------------------------------------------------------------------
    | Kafka Connections
    |--------------------------------------------------------------------------
    |
    | Here are each of the Kafka connections setup for your application.
    | Of course, examples of configuring each Kafka platform that is
    | supported by Laravel is shown below to make development simple.
    |
    */

    'connections' => [
        'default' => [
            'consumer' => [
                'brokers' => env('KAFKA_BROKERS', 'kafka:29092'),
                'group_id' => env('KAFKA_CONSUMER_GROUP_ID', 'payments_consumer_group'),
                'group_instance_id' => null,
                'auto_offset_reset' => 'earliest',
                'enable_auto_commit' => true,
                'auto_commit_interval_ms' => 1000,
                'compression' => 'snappy',
                'partition_assignment_strategy' => 'range',
                'max_poll_records' => 1000,
                'max_poll_interval_ms' => 300000,
                'session_timeout_ms' => 30000,
                'security_protocol' => 'PLAINTEXT',
                'sasl' => [
                    'mechanisms' => 'PLAIN',
                    'username' => null,
                    'password' => null,
                ],
                'dlq' => [
                    'topic' => 'payments-dlq',
                ],
                'auto_create_topics' => true,
            ],
            'producer' => [
                'brokers' => env('KAFKA_BROKERS', 'kafka:29092'),
                'compression' => 'snappy',
                'timeout' => 30000, // Increase timeout to 30 seconds
                'required_acknowledgment' => 1,
                'is_async' => false,
                'max_poll_records' => 500,
                'flush_attempts' => 10,
                'security_protocol' => 'PLAINTEXT',
                'auto_create_topics' => true,
                'sasl' => [
                    'mechanisms' => 'PLAIN',
                    'username' => null,
                    'password' => null,
                ],
            ],
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Global consumer options
    |--------------------------------------------------------------------------
    |
    | Here you can specify global consumer options, which will be used for
    | all consumers.
    |
    */

    'consumer' => [
        'timeout' => 120,
        'group_id' => env('KAFKA_CONSUMER_GROUP_ID', 'payments_consumer_group'),
        'brokers' => env('KAFKA_BROKERS', 'kafka:29092'),
        'security_protocol' => env('KAFKA_SECURITY_PROTOCOL', 'PLAINTEXT'),
        'sasl' => [
            'mechanisms' => env('KAFKA_SASL_MECHANISMS', 'PLAIN'),
            'username' => env('KAFKA_SASL_USERNAME'),
            'password' => env('KAFKA_SASL_PASSWORD'),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Global producer options
    |--------------------------------------------------------------------------
    |
    | Here you can specify global producer options, which will be used for
    | all producers.
    |
    */

    'producer' => [
        'brokers' => env('KAFKA_BROKERS', 'kafka:29092'),
        'security_protocol' => env('KAFKA_SECURITY_PROTOCOL', 'PLAINTEXT'),
        'sasl' => [
            'mechanisms' => env('KAFKA_SASL_MECHANISMS', 'PLAIN'),
            'username' => env('KAFKA_SASL_USERNAME'),
            'password' => env('KAFKA_SASL_PASSWORD'),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Kafka cache driver
    |--------------------------------------------------------------------------
    |
    | Here you can specify the cache driver to be used by the library to
    | store the schemas. The cache driver must be one of the drivers
    | configured in your application cache configuration.
    |
    */

    'cache_driver' => env('KAFKA_CACHE_DRIVER', 'redis'),
];
