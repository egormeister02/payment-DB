# Блокировка платежей

В предложенной структуре базы данных три таблицы:
`clients`, `payment_status` и `history_payment_blocks`.
- `clients` хранит информацию о клиентах
- `payment_status` хранит информацию о статусе платежей клиента
- `history_payment_blocks` хранит историю блокировок клиента

`history_payment_blocks` хранит только информации о блокировании платежей, информации о разблокировании она не содержит, так как она излишняя\
(все время пока платежи не блокированы они считаются разблокированы)
## Тригеры
В файлье `trigers.sql` содержатся тригеры, которые я решил добавить для функционирования бд.\
В основном они требуются для автоматизации работы с таблицей `history_payment_blocks`

## Спецификация
В файле `specification.yaml` содержится спецификация endpoint’ов.\
Помимо endpoint’ов указанных в задании я решил реализовать возможность получения истории блокировок клиента.