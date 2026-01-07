# Управление трафиком внутри кластера Kubernetes

Это задание демонстрирует использование сетевых политик Kubernetes для изоляции трафика между сервисами.

## Структура

В кластере развернуты 4 сервиса с метками:
- `front-end` - фронтенд приложения
- `back-end-api` - бэкенд API
- `admin-front-end` - админский фронтенд
- `admin-back-end-api` - админский бэкенд API

## Сетевые политики

Сетевые политики настроены так, чтобы:
- ✅ Разрешить трафик между `front-end` и `back-end-api` (в обе стороны)
- ✅ Разрешить трафик между `admin-front-end` и `admin-back-end-api` (в обе стороны)
- ❌ Запретить трафик между другими комбинациями сервисов

## Развертывание

### Вариант 1: Использование готовых манифестов

```bash
# Применить все манифесты
chmod +x apply-all.sh
./apply-all.sh
```

### Вариант 2: Ручное развертывание с kubectl run

Если вы хотите использовать команды `kubectl run` как указано в задании:

```bash
# Создание подов и сервисов
kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80

# Применение сетевых политик
kubectl apply -f non-admin-api-allow.yaml
kubectl apply -f admin-api-allow.yaml
```

## Применение сетевых политик

```bash
# Применить политику для non-admin сервисов
kubectl apply -f non-admin-api-allow.yaml

# Применить политику для admin сервисов
kubectl apply -f admin-api-allow.yaml
```

## Проверка трафика

### Автоматическая проверка

```bash
chmod +x test-traffic.sh
./test-traffic.sh
```

### Ручная проверка

Для проверки трафика используйте временный под:

```bash
# Проверка разрешенного трафика: front-end -> back-end-api
kubectl run test-$RANDOM --rm -i -t --image=alpine -- sh -c "wget -qO- --timeout=2 http://back-end-api-app"

# Проверка запрещенного трафика: front-end -> admin-back-end-api
kubectl run test-$RANDOM --rm -i -t --image=alpine --labels role=front-end -- sh -c "wget -qO- --timeout=2 http://admin-back-end-api-app"
```

Или используйте существующие поды:

```bash
# Получить имя пода front-end
POD_NAME=$(kubectl get pod -l role=front-end -o jsonpath='{.items[0].metadata.name}')

# Проверить доступ к back-end-api (должен работать)
kubectl exec $POD_NAME -- wget -qO- --timeout=2 http://back-end-api-app

# Проверить доступ к admin-back-end-api (должен быть заблокирован)
kubectl exec $POD_NAME -- wget -qO- --timeout=2 http://admin-back-end-api-app
```

## Проверка статуса

```bash
# Проверить статус подов
kubectl get pods -l role=front-end
kubectl get pods -l role=back-end-api
kubectl get pods -l role=admin-front-end
kubectl get pods -l role=admin-back-end-api

# Проверить сервисы
kubectl get services

# Проверить сетевые политики
kubectl get networkpolicies

# Посмотреть детали сетевой политики
kubectl describe networkpolicy non-admin-api-allow
kubectl describe networkpolicy admin-api-allow
```

## Очистка

```bash
# Удалить все ресурсы
kubectl delete -f front-end-app.yaml
kubectl delete -f back-end-api-app.yaml
kubectl delete -f admin-front-end-app.yaml
kubectl delete -f admin-back-end-api-app.yaml
kubectl delete -f non-admin-api-allow.yaml
kubectl delete -f admin-api-allow.yaml
```

## Важные замечания

1. **NetworkPolicy требует поддержки CNI плагина**: Убедитесь, что ваш кластер поддерживает NetworkPolicy (например, Calico, Cilium, Weave Net).

2. **Политики по умолчанию**: Если политика не указана, трафик разрешен. После применения политики, трафик разрешен только согласно правилам политики.

3. **Метки важны**: Убедитесь, что метки `role` правильно назначены всем подам.

4. **Проверка в правильном namespace**: Убедитесь, что все ресурсы созданы в одном namespace.

