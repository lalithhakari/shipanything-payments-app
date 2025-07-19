# Payments Microservice

This is the Payments microservice for the ShipAnything platform, handling payment processing, billing, and transaction management.

## Features

-   Payment processing
-   Transaction management
-   Billing and invoicing
-   Payment method management

## Endpoints

-   `GET /health` - Health check
-   `GET /api/test/dbs` - Database connectivity test
-   `GET /api/test/rabbitmq` - RabbitMQ connectivity test
-   `GET /api/test/kafka` - Kafka connectivity test

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
