<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ExtractUserContext
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Extract user information from headers set by NGINX
        $userId = $request->header('X-User-ID');
        $userEmail = $request->header('X-User-Email');

        if ($userId && $userEmail) {
            // Add user context to request
            $request->merge([
                'authenticated_user' => [
                    'id' => $userId,
                    'email' => $userEmail,
                ]
            ]);

            // You can also set this in the request attributes
            $request->attributes->set('user_id', $userId);
            $request->attributes->set('user_email', $userEmail);
        }

        return $next($request);
    }
}
