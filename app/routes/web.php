<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

// Demo endpoint: shows which pod answered and whether the database is reachable.
Route::get('/', function () {
    try {
        DB::select('select 1');
        $database = 'ok';
    } catch (Throwable $e) {
        $database = 'down';
    }

    return response()->json([
        'app' => config('app.name'),
        'pod' => gethostname(),
        'php' => PHP_VERSION,
        'database' => $database,
    ]);
});
