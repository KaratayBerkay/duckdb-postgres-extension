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
SELECT * from pg_settings;
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
Output:
```
              proname               
------------------------------------
 duckdb_alter_table_trigger
 duckdb_am_handler
 duckdb_create_table_trigger
 duckdb_drop_trigger
 duckdb_grant_trigger
 duckdb_secret_r2_check
 duckdb_update_extensions_table_seq
 duckdb_update_secrets_table_seq
(8 rows)
```

### Force postgres to use duckdb at executions
```
SET duckdb.force_execution = true;
```
Output:
```
SET
```
> Run all Queries below

# Step 2 Deploy Postgres only
### Run postgres terminal from terminal
```bash
docker exec -it postgres psql -U postgres
```
Enter your password from docker-compose.yml

> Run all Queries below

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
Output:
```
Timing is on.
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

# Output of Explain Analyze

Output duckdb:
```
postgres=# EXPLAIN ANALYZE 
SELECT 
    LEFT(username, POSITION(' ' IN username) - 1) AS first_name,  -- Extract first name
    COUNT(*) AS total_users,         -- Total users per first name
    MIN(created_at) AS first_user,   -- First user created with this name
    MAX(created_at) AS last_user,    -- Last user created with this name
    AVG(LENGTH(password_hash)) AS avg_password_length -- Average password hash length
FROM Users
GROUP BY first_name
ORDER BY total_users DESC;
Time: 24154.963 ms (00:24.155)
```
Output postgres:
```
postgres=# EXPLAIN ANALYZE
SELECT
    LEFT(username, POSITION(' ' IN username) - 1) AS first_name,  -- Extract first name
    COUNT(*) AS total_users,         -- Total users per first name
    MIN(created_at) AS first_user,   -- First user created with this name
    MAX(created_at) AS last_user,    -- Last user created with this name
    AVG(LENGTH(password_hash)) AS avg_password_length -- Average password hash length
FROM Users
GROUP BY first_name
ORDER BY total_users DESC;
                                                                        QUERY PLAN                                                                         
-----------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=5070110.59..5095111.16 rows=10000225 width=88) (actual time=70859.996..72819.581 rows=9561573 loops=1)
   Sort Key: (count(*)) DESC
   Sort Method: external merge  Disk: 578712kB
   ->  Finalize GroupAggregate  (cost=1059921.89..2471826.98 rows=10000225 width=88) (actual time=27442.569..63733.206 rows=9561573 loops=1)
         Group Key: ("left"((username)::text, (POSITION((' '::text) IN (username)) - 1)))
         ->  Gather Merge  (cost=1059921.89..2167653.48 rows=8333520 width=88) (actual time=27442.547..50330.700 rows=9561688 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  Partial GroupAggregate  (cost=1058921.87..1204758.47 rows=4166760 width=88) (actual time=27392.473..36375.765 rows=3187229 loops=3)
                     Group Key: ("left"((username)::text, (POSITION((' '::text) IN (username)) - 1)))
                     ->  Sort  (cost=1058921.87..1069338.77 rows=4166760 width=73) (actual time=27392.443..32522.655 rows=3333333 loops=3)
                           Sort Key: ("left"((username)::text, (POSITION((' '::text) IN (username)) - 1)))
                           Sort Method: external merge  Disk: 242152kB
                           Worker 0:  Sort Method: external merge  Disk: 240352kB
                           Worker 1:  Sort Method: external merge  Disk: 240320kB
                           ->  Parallel Seq Scan on users  (cost=0.00..230483.30 rows=4166760 width=73) (actual time=0.078..1816.893 rows=3333333 loops=3)
 Planning Time: 0.167 ms
 Execution Time: 73669.878 ms
(18 rows)

Time: 73671.140 ms (01:13.671)
```


# Other useful queries for duckdb

### Drop Extension
```
DROP EXTENSION IF EXISTS pg_duckdb CASCADE;
```
### Create Extension
```
CREATE EXTENSION pg_duckdb;
```

# What to do with it?
Duckdb extension can save chunks as parquet files and read them back. This is useful for data warehousing and data lake scenarios.
Able to read data from parquet files and write them back to database tables.