<h1 align="center">Data Science Project Template </h1>

> [!TIP]
> TL;DR: репозиторий со скриптами для запуска контейнеров c MinIO, MLflow, 
> создания репозитория по шаблону и подключения его к MinIO c DVC и MLflow.

Этот репозиторий — шаблон для создания небольших Data Science проектов. 
Он разработан для собственного удобства, чтобы сократить рутину при настройке инфраструктуры. 
Шаблон помогает организовать управление данными, моделями, экспериментами и воспроизводимость проекта.

# Структура

Шаблон разделён на два концептуальных уровня: инфраструктурный и проектный. 
Пояснение о взаимодействии сущностей между этими уровнями - на [диаграмме](#логическая-схема-инфраструктуры-и-данных).

Технически архитектура проекта состоит из контейнеров, которые запускаются и конфигурируются набором скриптов, 
ключевые элементы технической реализации - на [диаграмме](#диаграмма-контейнерной-архитектуры).

## 1. Уровень инфраструктуры

Этот уровень отвечает за общую настройку среды и управление инструментами и содержит шаблоны автоматизации для:

- Запуска контейнера с S3 совместимым хранилищем данных (по умолчанию - MinIO) для версионированния данных.
- Запуска контейнера с MLflow для логирования экспериментов.

Цель инфраструктурного уровня — создать универсальный каркас, который легко адаптируется под новые проекты. 
Если какие-то компоненты не нужны, их можно заменить или отключить.

## 2. Уровень проекта

Здесь находится всё, что нужно для работы с самим проектом:
- Создания виртуального окружения и конфигурации зависимостей.
- Подключения к компонентам инфраструктурного уровня.
- Запуска линтера и форматера (по умолчанию - [Ruff](https://docs.astral.sh/ruff/)).

<details>
<summary><b>Поясняющие диаграммы</b></summary>

## Логическая схема инфраструктуры и данных
![structure diagram](docs/src/structure%20diagram.png)

## Диаграмма контейнерной архитектуры
<div align="center">
  <img src="docs/src/container%20architecture%20diagram.png" alt="Centered Image">
</div>

</details> 

# Использование

<details>
<summary><b>Host Machine <-> Project</b></summary>

Настройка инфраструктуры и подключения к ней проекта требует выполнения команд на разных уровнях:
- на уровне хоста, т.е в `./` копии этого репозитория. 
    
    В начале блока команд, выполняемых на хосте помещена плашка - ![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)

- на уровне проекта, т.е. в `./` репозитория проекта на хосте или внутри devbox. 

    В начале блока команд, выполняемых в репозитории проекта помещена плашка - ![Runs on: Project root](https://img.shields.io/badge/Runs%20on-Project%20root-green)
</details> 

## Первичная настройка

![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)

- Скопируйте этот репозиторий

```bash 
git clone https://github.com/KorneevRV/DS_template_infrastructure
```
- Создайте `.env` файлы на основе шаблонов `*.env.template` вручную или скриптом: 

```bash
make env
```

- Запустите контейнеры
```bash
docker compose -f src/docker-compose.yml up -d
```

- Перейдите в [web-интерфейс MinIO](http://localhost:9001/), данные для авторизации - `infra/MinIO/.env`. Создайте ключ доступа, сохраните Access Key и Secret Key. Создайте два bucket:
    - `mlflow-artifacts` - для хранение артефактов модели через MLFlow API
    - `<your-data-bucket>` - для хранения данных

- **Добавьте учетные данные**. Добавление осуществятся через интерактивный CLI, как правило требуется изменить 
cозданные при [первичной настройке](#Первичная-настройка):
    - MinIO access key - сохраненный Access Key
    - MinIO secret key - сохраненный Secret Key

    Запуск CLI для редактирования учетных данных:
    ```bash
    make addcreds
    ```

- Запустите / перезапустите все контейнеры:
    ```bash
    docker compose -f src/docker-compose.yml up -d
    ```

## Настройка репозитория проекта

![Runs on: Project root](https://img.shields.io/badge/Runs%20on-Project%20root-green)
- **Создайте локальную копию репозитория проекта**

    Скопируйте имеющейся репозиторий при помощи `git clone` или инициализируйте новый при помощи `git init`. 

- **Скопируйте шаблон проекта**. При копировании шаблона в вашем локальном репозитории будет создана ветка `template`, в которую
 будет скопирована вся структура (т.е все файлы кроме README.md) из [шаблона](https://github.com/KorneevRV/DS_template).

    - Скачайте `makefile` из [репозитория с шаблоном проекта](https://github.com/KorneevRV/DS_template):
    ```
    wget https://raw.githubusercontent.com/KorneevRV/DS_template/main/makefile
    ```
    - Запуск копирования шаблона:
    ```bash
    make template
    ```
    - Перейдите в ветку `template`. При необходимости измените набор библиотек, устанавливаемых по умолчанию, заполните README,
    внесите изменения в структуру.
    ```bash
    git checkout template
    ```
    - Слейте ветку `template` с веткой `main`:
    ```bash
    git commit
    git checkout main
    git merge template
    git branch -d template
    ```

- **Запустите установку библиотек для Python**. Скрипт создаст в вашем локальном репозитории виртуальное окружение при помощи `venv` и установит в него все библиотеки из файла `requirements.txt` Скрипт для запуска установки библиотек:
    
    ```bash
    make install
    ```

## Подключение DVC
![Runs on: Project root](https://img.shields.io/badge/Runs%20on-Project%20root-green)

- Создайте файл для хранения учетных данных `creds.env` по шаблону `creds.env.template`:

    ``` bash
    cp creds.env.template creds.env
    ```

- **Добавьте учетные данные**. Добавление осуществятся через интерактивный CLI, как правило требуется изменить 
cозданные при [первичной настройке](#Первичная-настройка):
    - MinIO URL - по умолчанию http://localhost:9000, если код репозитория расположен не на хосте контейнера c MinIO, то нужно изменить на верный URL. 
    - MinIO access key - сохраненный Access Key
    - MinIO secret key - сохраненный Secret Key
    - MinIO bucket name - сохраненное имя bucket для этого проекта
    
    Запуск CLI для редактирования учетных данных:
    ``` bash
    make addcreds
    ```

- **Запустите скрипт для подключения DVC**. 
    
    Скрипт создаст ветку `dvc` в вашем локальном репозитории, выполнит инициализацию DVC, добавит директорию `/data` в отслеживаемые DVC.

    ```bash
    make adddvc
    ```

- Перейдите в ветку `dvc`, выполните первый коммит в DVC. После этого рекомендуется слить ветки `dvc` и `main`.
    ```bash
    dvc commit
    git add .
    git commit
    git checkout main
    git merge dvc
    git branch -d dvc
    ```

## Рабочий процесс

После того, как все предыдущие пункты выполнены - локальный репозиторий в DevBox готов к работе. Обычный рабочий процесс состоит из следующих шагов:

![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)
- **Запустите контейнеры**
```bash
docker compose -f src/docker-compose.yml up -d
```

- Модифицируйте код, версионируйте данные, артефакты и эксперименты при помощи DVC и MLFlow.

    - Веб-интрефейс MLFlow: [http://localhost:5000/](http://localhost:5000/)
    - Код для обращения к MLFlow API: 
    ```python
    mlflow.set_tracking_uri(uri='http://localhost:5000/')

    mlflow.set_experiment(<your-experiment>)

    with mlflow.start_run():
        mlflow.log_params(<params>)
        ...
    ```
    - Веб-интерфейс MinIO: [http://localhost:9001/](http://localhost:9001/)
- В качестве линтера используйте установленный [Ruff](https://docs.astral.sh/ruff/). Запуск проверки:
    ```
    ruff check
    ```

![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)
- По окончанию работы включите все контейнеры
```bash
docker compose -f src/docker-compose.yml down
```

