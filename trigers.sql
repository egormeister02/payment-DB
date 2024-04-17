ALTER DATABASE your_database_name SET pg_temp.allow_insert TO 'false';


-- Создание функции триггера
CREATE OR REPLACE FUNCTION add_payment_status_for_new_client()
RETURNS TRIGGER AS 
$$
BEGIN
    -- Вставка строки в таблицу payment_status с client_id нового клиента и статусом 'unblock'
    SET LOCAL pg_temp.allow_insert = 'true';
    INSERT INTO payment_status (client_id, status_value, reason_value)
    VALUES (NEW.client_id, 'unblock', 'not_blocked');
    RESET pg_temp.allow_insert;
    
    -- Возврат новой строки для продолжения операции вставки
RETURN NEW;
END;
$$ 
LANGUAGE 'plpgsql';

-- Создание триггера
CREATE TRIGGER trigger_add_payment_status_after_client_insert
    AFTER INSERT ON clients
    FOR EACH ROW
    EXECUTE FUNCTION add_payment_status_for_new_client();


-- Создание функции триггера
CREATE OR REPLACE FUNCTION update_history_payment_blocks()
RETURNS TRIGGER AS 
$$
DECLARE
    last_history_id INT;
BEGIN
    -- Если статус изменен на 'blocked', добавляем новую запись в history_payment_blocks
    IF NEW.status_value = 'block' AND OLD.status_value = 'unblock' THEN
        SET LOCAL pg_temp.allow_insert = 'true';
        INSERT INTO history_payment_blocks (client_id, reason_value, date_from_dttm, date_to_dttm)
        VALUES (NEW.client_id, NEW.reason_value, CURRENT_TIMESTAMP, 'infinity');
        RESET pg_temp.allow_insert;

    -- Если статус изменен на 'unblocked', обновляем date_to_dttm последней записи для этого клиента
    ELSIF NEW.status_value = 'unblock' AND OLD.status_value = 'block' THEN
        SELECT history_id INTO last_history_id FROM history_payment_blocks
        WHERE client_id = NEW.client_id AND date_to_dttm = 'infinity'
        ORDER BY date_from_dttm DESC
        LIMIT 1;

        UPDATE history_payment_blocks
        SET date_to_dttm = CURRENT_TIMESTAMP
        WHERE history_id = last_history_id;
    END IF;
RETURN NEW;
END;
$$ 
LANGUAGE 'plpgsql';

-- Создание триггера
CREATE TRIGGER trigger_update_history_after_payment_status_change
    AFTER UPDATE ON payment_status
    FOR EACH ROW
    WHEN (OLD.status_value IS DISTINCT FROM NEW.status_value)
    EXECUTE FUNCTION update_history_payment_blocks();

   -- Создание функции триггера, которая отменяет вставку
CREATE OR REPLACE FUNCTION prevent_manual_inserts_history()
   RETURNS TRIGGER AS $$
   BEGIN
        -- Проверяем, установлена ли сессионная переменная
        IF current_setting('pg_temp.allow_insert', true) = 'true' THEN
            -- Если переменная установлена, вставка разрешена
            RETURN NEW;
        ELSE
            -- Если переменная не установлена, вставка запрещена
            RAISE EXCEPTION 'Direct inserts into history_payment_blocks are not allowed.';
        END IF;
   END;
   $$ 
   LANGUAGE plpgsql;

   -- Создание триггера, который вызывает эту функцию перед вставкой
CREATE TRIGGER prevent_manual_inserts_trigger_history
   BEFORE INSERT ON history_payment_blocks
   FOR EACH ROW
   EXECUTE FUNCTION prevent_manual_inserts_history();

   -- Создание функции триггера, которая отменяет вставку
CREATE OR REPLACE FUNCTION prevent_manual_inserts_status()
   RETURNS TRIGGER AS $$
   BEGIN
       IF current_setting('pg_temp.allow_insert', true) = 'true' THEN
            -- Если переменная установлена, вставка разрешена
            RETURN NEW;
        ELSE
            -- Если переменная не установлена, вставка запрещена
            RAISE EXCEPTION 'Direct inserts into history_payment_blocks are not allowed.';
        END IF;
   END;
   $$ 
   LANGUAGE plpgsql;

   -- Создание триггера, который вызывает эту функцию перед вставкой
CREATE TRIGGER prevent_manual_inserts_trigger_status
   BEFORE INSERT ON payment_status
   FOR EACH ROW
   EXECUTE FUNCTION prevent_manual_inserts_status();