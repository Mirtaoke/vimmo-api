<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'kkiapay' => [
        'public_key' => env('KKIAPAY_PUBLIC_KEY'),
        'private_key' => env('KKIAPAY_PRIVATE_KEY'),
        'secret' => env('KKIAPAY_SECRET'),
        'sandbox' => filter_var(env('KKIAPAY_SANDBOX', true), FILTER_VALIDATE_BOOL),
        'webhook_secret' => env('KKIAPAY_WEBHOOK_SECRET'),
        'base_url' => filter_var(env('KKIAPAY_SANDBOX', true), FILTER_VALIDATE_BOOL)
            ? 'https://api-sandbox.kkiapay.me'
            : 'https://api.kkiapay.me',
        'callback_url' => env('KKIAPAY_CALLBACK_URL'),
        'theme' => env('KKIAPAY_THEME', '#148477'),
        'countries' => array_values(array_filter(explode(',', env('KKIAPAY_COUNTRIES', 'BJ')))),
        'payment_methods' => array_values(array_filter(explode(',', env('KKIAPAY_PAYMENT_METHODS', 'momo,card')))),
    ],

];
