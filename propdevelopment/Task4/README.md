# Защита доступа к кластеру Kubernetes

## Описание решения

Данное решение реализует ролевой доступ (RBAC) к кластеру Kubernetes для различных групп пользователей с разграничением прав доступа в соответствии с организационной структурой компании.

## Структура решения

### 1. Привилегированные администраторы (`01-privileged-admins-clusterrole.yaml`)

**Группа**: `privileged-admins`

**Права доступа**:
- Полный доступ ко всем ресурсам кластера
- Доступ к секретам (просмотр, создание, изменение, удаление)
- Управление всеми ресурсами во всех namespace
- Доступ к узлам кластера
- Выполнение команд в подах
- Проброс портов

**Применение**: Для администраторов безопасности и DevOps-инженеров, которым необходим полный контроль над кластером.

### 2. Пользователи только для просмотра (`02-read-only-viewers-clusterrole.yaml`)

**Группа**: `read-only-viewers`

**Права доступа**:
- Только просмотр всех ресурсов кластера
- **Нет доступа к секретам**
- Просмотр логов подов (только чтение)
- Просмотр событий и метрик

**Применение**: Для менеджеров, аналитиков и других пользователей, которым нужен только мониторинг состояния кластера без возможности внесения изменений.

### 3. Операторы кластера (`03-cluster-operators-clusterrole.yaml`)

**Группа**: `cluster-operators`

**Права доступа**:
- Управление подами, сервисами, развертываниями
- Управление ingress и конфигурационными картами
- Управление persistent volumes
- Выполнение команд в подах для отладки
- Проброс портов
- Управление горизонтальными автомасштабировщиками
- **Нет доступа к секретам**

**Применение**: Для DevOps-инженеров и операторов, которые настраивают и управляют приложениями в кластере, но не должны иметь доступ к секретным данным.

### 4. Разграничение доступа по организационной структуре (`04-namespace-based-roles.yaml`)

Решение включает роли на уровне namespace для различных команд компании:

#### Команда разработки (`development` namespace)
- **Группа**: `development-team`
- Полное управление ресурсами в namespace `development`
- Просмотр секретов (без изменения)
- Выполнение команд в подах

#### Команда тестирования (`testing` namespace)
- **Группа**: `testing-team`
- Просмотр ресурсов в namespace `testing`
- Создание тестовых подов
- Нет доступа к секретам

#### Команда продакшена (`production` namespace)
- **Группа**: `production-team`
- Просмотр ресурсов (мониторинг)
- Ограниченное управление (только масштабирование)
- Нет доступа к секретам

#### Команда безопасности (`security` namespace)
- **Группа**: `security-team`
- Доступ к секретам для аудита безопасности
- Просмотр всех ресурсов для мониторинга безопасности

## Установка и применение

### Предварительные требования

1. Доступ к кластеру Kubernetes с правами администратора
2. Настроенная система аутентификации (например, LDAP, Active Directory, OIDC)
3. Группы пользователей должны быть настроены в системе аутентификации

### Шаги установки

1. **Создайте необходимые namespace** (если они еще не существуют):

```bash
kubectl create namespace development
kubectl create namespace testing
kubectl create namespace production
kubectl create namespace security
```

2. **Примените манифесты в следующем порядке**:

```bash
# 1. Привилегированные администраторы
kubectl apply -f 01-privileged-admins-clusterrole.yaml

# 2. Пользователи только для просмотра
kubectl apply -f 02-read-only-viewers-clusterrole.yaml

# 3. Операторы кластера
kubectl apply -f 03-cluster-operators-clusterrole.yaml

# 4. Роли по namespace (организационная структура)
kubectl apply -f 04-namespace-based-roles.yaml
```

3. **Проверьте созданные роли и привязки**:

```bash
# Проверка ClusterRoles
kubectl get clusterroles | grep -E "privileged-admin|read-only-viewer|cluster-operator"

# Проверка ClusterRoleBindings
kubectl get clusterrolebindings | grep -E "privileged-admin|read-only-viewer|cluster-operator"

# Проверка Roles в namespace
kubectl get roles -n development
kubectl get roles -n testing
kubectl get roles -n production
kubectl get roles -n security
```

## Настройка групп пользователей

### Интеграция с системой аутентификации

Манифесты используют группы пользователей для привязки ролей. Необходимо настроить систему аутентификации Kubernetes так, чтобы она передавала информацию о группах пользователей.

#### Пример для OIDC:

В конфигурации API-сервера Kubernetes добавьте:

```yaml
--oidc-issuer-url=https://your-oidc-provider
--oidc-client-id=kubernetes
--oidc-username-claim=email
--oidc-groups-claim=groups
```

#### Пример для LDAP:

Настройте LDAP-аутентификацию через webhook или используйте Dex/Keycloak в качестве промежуточного слоя.

### Создание групп пользователей

В вашей системе аутентификации создайте следующие группы:

- `privileged-admins` - Привилегированные администраторы
- `read-only-viewers` - Пользователи только для просмотра
- `cluster-operators` - Операторы кластера
- `development-team` - Команда разработки
- `testing-team` - Команда тестирования
- `production-team` - Команда продакшена
- `security-team` - Команда безопасности

## Проверка работы

### Тестирование прав доступа

1. **Проверка привилегированного администратора**:

```bash
# Войдите как пользователь из группы privileged-admins
kubectl auth can-i get secrets --all-namespaces
# Должно вернуть: yes

kubectl auth can-i create pods --all-namespaces
# Должно вернуть: yes
```

2. **Проверка пользователя только для просмотра**:

```bash
# Войдите как пользователь из группы read-only-viewers
kubectl auth can-i get pods --all-namespaces
# Должно вернуть: yes

kubectl auth can-i get secrets --all-namespaces
# Должно вернуть: no

kubectl auth can-i create pods
# Должно вернуть: no
```

3. **Проверка оператора кластера**:

```bash
# Войдите как пользователь из группы cluster-operators
kubectl auth can-i create deployments
# Должно вернуть: yes

kubectl auth can-i get secrets
# Должно вернуть: no
```

4. **Проверка доступа по namespace**:

```bash
# Войдите как пользователь из группы development-team
kubectl auth can-i create pods -n development
# Должно вернуть: yes

kubectl auth can-i create pods -n production
# Должно вернуть: no
```

## Безопасность

### Рекомендации

1. **Минимальные привилегии**: Принцип наименьших привилегий реализован - каждая группа имеет только необходимые права.

2. **Защита секретов**: Секреты доступны только привилегированным администраторам и команде безопасности.

3. **Разделение по namespace**: Разные команды имеют доступ только к своим namespace, что предотвращает случайное воздействие на другие среды.

4. **Аудит**: Все действия пользователей логируются Kubernetes API-сервером. Рекомендуется настроить централизованный сбор логов.

5. **Регулярный пересмотр**: Регулярно пересматривайте права доступа и удаляйте неиспользуемые привязки.

### Дополнительные меры безопасности

- Используйте Network Policies для дополнительной изоляции
- Настройте Pod Security Standards для ограничения привилегий подов
- Используйте Service Accounts с минимальными правами для подов
- Регулярно обновляйте Kubernetes и применяйте патчи безопасности

## Кастомизация

### Добавление новых групп

Для добавления новой группы пользователей:

1. Создайте новый файл с манифестом Role или ClusterRole
2. Определите необходимые права доступа
3. Создайте RoleBinding или ClusterRoleBinding
4. Примените манифест: `kubectl apply -f <файл>`

### Изменение существующих ролей

Для изменения прав существующей роли:

1. Отредактируйте соответствующий манифест
2. Примените изменения: `kubectl apply -f <файл>`

Изменения применяются немедленно без перезапуска кластера.

## Устранение неполадок

### Проблема: Пользователь не может выполнить действие

1. Проверьте, к какой группе принадлежит пользователь:
   ```bash
   kubectl auth can-i <verb> <resource> --as=<user>
   ```

2. Проверьте привязки ролей:
   ```bash
   kubectl get clusterrolebindings -o wide
   kubectl get rolebindings -n <namespace> -o wide
   ```

3. Проверьте права роли:
   ```bash
   kubectl describe clusterrole <role-name>
   kubectl describe role <role-name> -n <namespace>
   ```

### Проблема: Группы пользователей не распознаются

1. Проверьте конфигурацию аутентификации API-сервера
2. Убедитесь, что система аутентификации передает информацию о группах
3. Проверьте токены пользователей (должны содержать информацию о группах)

## Дополнительные ресурсы

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#using-rbac-authorization)
- [RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)

