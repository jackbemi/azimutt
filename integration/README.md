In this folder we set up several databases with default schema and data to serve as example for database access & data exploration.
We could also set up some integration tests with them...

Start them with: `docker compose up -d`
Stop them with: `docker compose down`
Start only one: `docker compose up <service>`
Check which services are running: `docker ps`

Connection urls:
- Couchbase:
- MariaDB:
- MongoDB:
- MySQL: `mysql://mysql:mysql@localhost:3306/azimutt_sample`
- PostgreSQL: `postgres://postgres:postgres@localhost:5432/azimutt_sample`
- SQL Server:

Each database has an "interesting" database to experiment Azimutt features.

sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose