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