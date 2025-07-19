<?php

return [
    'host' => env('RABBITMQ_HOST', 'payments-rabbitmq'),
    'port' => env('RABBITMQ_PORT', 5672),
    'user' => env('RABBITMQ_USER', 'payments_user'),
    'password' => env('RABBITMQ_PASSWORD', 'payments_password'),
];
