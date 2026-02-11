#!/bin/bash

# Скрипт для проверки сетевого трафика между сервисами

echo "=== Тестирование сетевого трафика ==="
echo ""

# Функция для тестирования подключения
test_connection() {
    local from_role=$1
    local to_service=$2
    local expected_result=$3
    
    echo "Тест: $from_role -> $to_service (ожидается: $expected_result)"
    
    # Получаем имя пода с нужной меткой
    POD_NAME=$(kubectl get pod -l role=$from_role -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$POD_NAME" ]; then
        echo "  ❌ Под с меткой $from_role не найден"
        return
    fi
    
    # Пытаемся подключиться
    RESULT=$(kubectl exec $POD_NAME -- wget -qO- --timeout=2 http://$to_service 2>&1)
    
    if [ $? -eq 0 ] && [ "$expected_result" == "разрешено" ]; then
        echo "  ✅ Трафик разрешен (как и ожидалось)"
    elif [ $? -ne 0 ] && [ "$expected_result" == "запрещено" ]; then
        echo "  ✅ Трафик запрещен (как и ожидалось)"
    elif [ $? -eq 0 ] && [ "$expected_result" == "запрещено" ]; then
        echo "  ❌ ОШИБКА: Трафик разрешен, но должен быть запрещен!"
    else
        echo "  ❌ ОШИБКА: Трафик запрещен, но должен быть разрешен!"
    fi
    echo ""
}

echo "1. Тестирование разрешенных соединений:"
test_connection "front-end" "back-end-api-app" "разрешено"
test_connection "back-end-api" "front-end-app" "разрешено"
test_connection "admin-front-end" "admin-back-end-api-app" "разрешено"
test_connection "admin-back-end-api" "admin-front-end-app" "разрешено"

echo "2. Тестирование запрещенных соединений:"
test_connection "front-end" "admin-back-end-api-app" "запрещено"
test_connection "admin-front-end" "back-end-api-app" "запрещено"
test_connection "back-end-api" "admin-front-end-app" "запрещено"
test_connection "admin-back-end-api" "front-end-app" "запрещено"

echo "=== Тестирование завершено ==="

