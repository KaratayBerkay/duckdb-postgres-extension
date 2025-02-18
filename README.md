# Duckdb Postgres Extension
Duckdb integrated and no extension postgres compare

# Run compose yml
> Run both postgres/duckdb databases with docker compose 
```bash
docker compose up --build -d
```

# Configuration Changes
As an extension postgres duckdb library:/var/lib/postgresql/data/postgresql.conf
> postgresql.conf must have

```properties
#------------------------------------------------------------------------------
# CUSTOMIZED OPTIONS
#------------------------------------------------------------------------------
# Add settings for extensions here

shared_preload_libraries = 'pg_duckdb'
```

> or check with SQL statement
```
select * from pg_settings;
```


# Step 1 Deploy Postgres with duckdb

### Run postgres terminal from terminal
```bash
docker exec -it duckdb_postgres psql -U postgres
```
Enter your password from docker-compose.yml

### Check duckdb functions are available
```
SELECT proname FROM pg_proc WHERE proname LIKE 'duckdb%';
```

### Force postgres to use duckdb at executions
```
SET duckdb.force_execution = true;
```

# Queries

## Create Users Table and Insert 10M records
```
CREATE TABLE IF NOT EXISTS Users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DO $$
DECLARE
    i INT := 1;
    firstnames TEXT[] := ARRAY['John', 'Jane', 'Alex', 'Emily', 'Michael', 'Sarah', 'David', 'Laura', 'Robert', 'Olivia'];
    lastnames TEXT[] := ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Martinez', 'Hernandez'];
    fname TEXT;
    lname TEXT;
BEGIN
    WHILE i <= 10000000 LOOP
        fname := firstnames[1 + floor(random() * array_length(firstnames, 1))::int];
        lname := lastnames[1 + floor(random() * array_length(lastnames, 1))::int];

        INSERT INTO Users (username, email, password_hash, created_at)
        VALUES (
            fname || lname || i,
            fname || lname || i || '@example.com',
            md5(random()::text),
            NOW()
        );

        i := i + 1;
    END LOOP;
END $$;
```
### Set timing ON
```
\timing
```
### Explain Analyze Query
```
EXPLAIN ANALYZE 
SELECT 
    LEFT(username, POSITION(' ' IN username) - 1) AS first_name,  -- Extract first name
    COUNT(*) AS total_users,         -- Total users per first name
    MIN(created_at) AS first_user,   -- First user created with this name
    MAX(created_at) AS last_user,    -- Last user created with this name
    AVG(LENGTH(password_hash)) AS avg_password_length -- Average password hash length
FROM Users
GROUP BY first_name
ORDER BY total_users DESC;
```
### Drop Extension
```
DROP EXTENSION IF EXISTS pg_duckdb CASCADE;
```
### Create Extension
```
CREATE EXTENSION pg_duckdb;
```