-- Создание таблицы clients
CREATE TABLE clients (
    client_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
    -- дальше может идти другая необходимая информация о клиенте
);

-- Создание таблицы payment_status
CREATE TABLE payment_status (
    client_id INT UNIQUE,
    status_value VARCHAR(10) NOT NULL CHECK (status_value IN ('block', 'unblock')),
    reason_value VARCHAR(255) NOT NULL CHECK (((reason_value IN ('fraud', 'incorrect_details') AND status_value = 'block')) 
                                              OR (reason_value = 'not blocked' AND status_value = 'unblock')),

        FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

-- Создание таблицы history_payment_blocks
CREATE TABLE history_payment_blocks (
    history_id SERIAL PRIMARY KEY,
    client_id INT,
    reason_value VARCHAR(255) NOT NULL CHECK (reason_value IN ('fraud', 'incorrect_details')),
    date_from_dttm TIMESTAMP NOT NULL,
    date_to_dttm TIMESTAMP NOT NULL,

        FOREIGN KEY (client_id) REFERENCES clients(client_id)
);
