#!/bin/bash

# Скрипт для проверки прав доступа различных групп
# Использование: ./verify-access.sh [username]

set -e

USER="${1:-}"

if [ -z "$USER" ]; then
    echo "Использование: $0 <username>"
    echo "Пример: $0 user@example.com"
    exit 1
fi

echo "=========================================="
echo "Проверка прав доступа для: $USER"
echo "=========================================="
echo ""

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Ошибка: kubectl не найден."
    exit 1
fi

echo "Проверка базовых прав доступа:"
echo ""

# Проверка доступа к секретам
echo "1. Доступ к секретам (все namespace):"
if kubectl auth can-i get secrets --all-namespaces --as="$USER" 2>/dev/null; then
    echo "   ✓ Есть доступ к секретам"
else
    echo "   ✗ Нет доступа к секретам"
fi

# Проверка создания подов
echo "2. Создание подов:"
if kubectl auth can-i create pods --as="$USER" 2>/dev/null; then
    echo "   ✓ Может создавать поды"
else
    echo "   ✗ Не может создавать поды"
fi

# Проверка просмотра подов
echo "3. Просмотр подов:"
if kubectl auth can-i get pods --as="$USER" 2>/dev/null; then
    echo "   ✓ Может просматривать поды"
else
    echo "   ✗ Не может просматривать поды"
fi

# Проверка создания развертываний
echo "4. Создание развертываний:"
if kubectl auth can-i create deployments --as="$USER" 2>/dev/null; then
    echo "   ✓ Может создавать развертывания"
else
    echo "   ✗ Не может создавать развертывания"
fi

# Проверка доступа к узлам
echo "5. Доступ к узлам кластера:"
if kubectl auth can-i get nodes --as="$USER" 2>/dev/null; then
    echo "   ✓ Может просматривать узлы"
else
    echo "   ✗ Не может просматривать узлы"
fi

echo ""
echo "Проверка доступа по namespace:"
echo ""

for ns in development testing production security; do
    echo "Namespace: $ns"
    
    # Проверка создания подов в namespace
    if kubectl auth can-i create pods -n "$ns" --as="$USER" 2>/dev/null; then
        echo "   ✓ Может создавать поды"
    else
        echo "   ✗ Не может создавать поды"
    fi
    
    # Проверка просмотра секретов в namespace
    if kubectl auth can-i get secrets -n "$ns" --as="$USER" 2>/dev/null; then
        echo "   ✓ Может просматривать секреты"
    else
        echo "   ✗ Не может просматривать секреты"
    fi
    
    echo ""
done

echo "=========================================="
echo "Проверка завершена"
echo "=========================================="

