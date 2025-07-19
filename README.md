# Payments Microservice

This is the Payments microserv## User Context

**This service automatically receives user context from the NGINX API Gateway:**

-   User ID is available in controllers via `$request->attributes->get('user_id')`
-   User email via `$request->attributes->get('user_email')`
-   All payment data is automatically filtered by authenticated user
-   Enhanced security for financial transactions

**Example usage in controller:**

````php
public function getPayments(Request $request)
{
    $userId = $request->attributes->get('user_id');
    $userEmail = $request->attributes->get('user_email');

    // Get payments for the authenticated user only
    $payments = Payment::where('user_id', $userId)->get();

    return response()->json($payments);
}
``` the ShipAnything platform, handling payment processing, billing, and transaction management. **This service is protected by the Auth Gateway and requires a valid Bearer token for API access.**

## Features

- Payment processing and gateway integration
- Transaction management and history
- Billing and invoicing
- Payment method management
- User-specific payment data and security

## Authentication

**All API endpoints (except health check) are protected by the NGINX API Gateway and require a valid Bearer token.**

The authentication flow works as follows:
1. Client sends request to `http://payments.shipanything.test/api/*` with Bearer token
2. NGINX API Gateway intercepts and validates the token with the auth service
3. If valid, NGINX forwards the request with user context headers to this service
4. This service processes the request with authenticated user context

**Example API call:**
```bash
curl -X GET http://payments.shipanything.test/api/payments \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
````

**To get an access token, register/login via the Auth service:**

```bash
# Login to get token
curl -X POST http://auth.shipanything.test/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "your@email.com", "password": "yourpassword"}'
```

## API Endpoints

### Public Endpoints (No Authentication Required)

-   `GET /health` - Service health check

### Protected Endpoints (Require Bearer Token)

-   `GET /api/payments` - Get user's payment history
-   `POST /api/payments` - Process new payment
-   `GET /api/payments/{id}` - Get specific payment details
-   `GET /api/payment-methods` - Get user's payment methods
-   `POST /api/payment-methods` - Add new payment method
-   `DELETE /api/payment-methods/{id}` - Remove payment method

### Internal Test Endpoints (Container Network Only)

-   `GET /api/test/dbs` - Database connectivity test
-   `GET /api/test/rabbitmq` - RabbitMQ connectivity test
-   `GET /api/test/kafka` - Kafka connectivity test
-   `GET /api/test/auth-status` - Authentication status check

## User Context

The service automatically receives user context from the Auth Gateway:

-   User ID is available in controllers via `$request->attributes->get('user_id')`
-   User email via `$request->attributes->get('user_email')`
-   All payment data is automatically filtered by authenticated user
-   Enhanced security for financial operations

## Environment Variables

-   `DB_HOST` - PostgreSQL host (`payments-postgres`)
-   `DB_DATABASE` - Database name (`payments_db`)
-   `DB_USERNAME` - Database user (`payments_user`)
-   `DB_PASSWORD` - Database password (`payments_password`)
-   `REDIS_HOST` - Redis host (`payments-redis`)
-   `RABBITMQ_HOST` - RabbitMQ host (`payments-rabbitmq`)
-   `RABBITMQ_USER` - RabbitMQ user (`payments_user`)
-   `RABBITMQ_PASSWORD` - RabbitMQ password (`payments_password`)
-   `KAFKA_BROKERS` - Kafka brokers list (`kafka:29092`)

## Database Connection (Development)

**PostgreSQL:**

-   Host: `localhost`
-   Port: `5435`
-   Database: `payments_db`
-   Username: `payments_user`
-   Password: `payments_password`

**Redis:**

-   Host: `localhost`
-   Port: `6382`

**RabbitMQ Management UI:**

-   URL: http://localhost:15674
-   Username: `payments_user`
-   Password: `payments_password`

## Docker Compose Ports

-   **Application**: 8083
-   **PostgreSQL**: 5435
-   **Redis**: 6382
-   **RabbitMQ AMQP**: 5674
-   **RabbitMQ Management**: 15674

## Development

This service is part of the larger ShipAnything microservices platform. See the main repository README for setup and deployment instructions.

### Running Commands

```bash
# Navigate to the docker folder
cd microservices/payments-app/docker

# Run artisan commands
./cmd.sh php artisan migrate
./cmd.sh php artisan make:controller PaymentController
./cmd.sh composer install
```
