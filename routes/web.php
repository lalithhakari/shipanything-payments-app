<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return 'Payments App - INSTANT UPDATES! ⚡️ Time: ' . date('H:i:s') . ' - Hot reload working! 🔥';
});
