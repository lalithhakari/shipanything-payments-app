<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/test/dbs', [App\Http\Controllers\TestController::class, 'testDbs']);
Route::get('/test/rabbitmq', [App\Http\Controllers\TestController::class, 'testRabbitMQ']);
Route::get('/test/kafka', [App\Http\Controllers\TestController::class, 'testKafka']);
