# Data Science Project Template

Этот репозиторий предоставляет готовый шаблон для быстрого создания каркаса небольшого Data Science проекта. Он включает в себя инструменты для управления данными, моделями, экспериментами и воспроизводимостью.

# Структура

![structure diagram](docs/src/structure%20diagram.png)

## 1. Уровень инфраструктуры

Этот уровень отвечает за общую настройку среды и управление инструментами и содержит шаблоны автоматизации для:

- Запуска контейнера с S3 совместимым хранилищем данных для версионированния данных.
- Запуска контейнера с MLflow для логирования экспериментов.
- Создание репозитория уровня проекта.

Цель инфраструктурного уровня — создать единый каркас, который легко адаптируется для новых проектов, поддерживает замену или полное отключение некоторых объектов.

## 2. Уровень проекта

Этот уровень содержит готовый шаблон репозитория с шаблонами автоматизации для:
- Создания виртуального окружения и конфигурации зависимостей.
- Подключения к компонентам инфраструктурного уровня.
- Запуска линтеров и форматеров.

# Использование

Для использования шаблонов скопируйте этот репозиторий:

```bash
git clone https://github.com/KorneevRV/DS_template_infrastructure
```

### Запуск контейнеров

- Запуск всей инфраструктуры:
```bash
cd infra && docker compose up dev-container
```

- Запуск только контейнера с devbox:
```bash
cd infra && docker compose up dev-container
```

### Копирование шаблона репозитория проекта

1. Создайте локальный git репозиторий нового проекта с файлом README.md в директории `/infra/workspace`. Эта директория будет подключена к контейнеру c devbox.
2. Создайте конфигурационный файл окружения по шаблону `creds.env.template`. Замените значение переменной `REPO_NAME` в нем на название своего репозитория `<your_repo_name>`.

```bash
cp creds.env.template creds.env
sed -i '/^REPO_NAME=/c\REPO_NAME=<your_repo_name>' creds.env
```

3. Запустить копирование шаблона скриптом `newproject`.
    
    Скрипт создаст новую ветку `template`, скопирует все файлы из [шаблона](https://github.com/KorneevRV/DS_template) кроме README.md и выполнит коммит с комментарием "Merge DS project template". 

```bash
make newproject
```

Рекомендуется доработать полученный репозиторий (например, заполнить файл README.md) и выполнить слияние с веткой main с помощью команды git merge.

### Подключение MinIO и DVC

1. Создайте конфигурационный файл MinIO по шаблону `infra\MinIO\.env.template`. Замените значение переменных `MINIO_ROOT_USER` и `MINIO_ROOT_PASSWORD` на пару `<your_root_user>`/`<your_root_password>`, которая будет использоваться для доступа к MinIO.

```bash
cp infra/MinIO/.env.template infra/MinIO/.env

sed -i 's/^MINIO_ROOT_USER=.*/MINIO_ROOT_USER=<your_root_user>/' infra/MinIO/.env

sed -i 's/^MINIO_ROOT_PASSWORD=.*/MINIO_ROOT_PASSWORD=<your_root_password>/' infra/MinIO/.env
```
2. Запустите контейнеры
3. Через веб-интерфейс MinIO ([localhost:9001](http://localhost:9001/)) создайте бакет и сгенерируйте ключи доступа. Эти данные нужно внести в конфигурационный файл `creds.env` в строки `MINIO_BUCKET_NAME`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`. 
```bash
sed -i '/^MINIO_BUCKET_NAME=/c\MINIO_BUCKET_NAME=<your_bucket>' creds.env
sed -i '/^MINIO_ACCESS_KEY=/c\MINIO_ACCESS_KEY=<your_akey>' creds.env
sed -i '/^MINIO_BUCKET_NAME=/c\MINIO_BUCKET_NAME=<your_bucket>' creds.env
```
4. Запустить скрипт подключения и конфигурации DVC.

    Скрипт выполнит инициализацию DVC в репозитории, добавит в DVC папку `data` и подключит DVC к бакету, который указан в `creds.env`.

    После выполнения скрипта рекомендуется загрузить свои данные и выполнить `dvc commit` и `git commit` для начала отслеживания состояния данных.

```bash
make adds3
```