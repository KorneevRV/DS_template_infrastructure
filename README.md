<h1 align="center">Data Science Project Template </h1>

Этот репозиторий — шаблон для создания небольших Data Science проектов. 
Он разработан для собственного удобства, чтобы сократить рутину при настройке инфраструктуры. 
Шаблон помогает организовать управление данными, моделями, экспериментами и воспроизводимость проекта.

> [!TIP]
> TL;DR: репозиторий со скриптами для запуска контейнеров c MinIO, MLflow, DevBox, 
> создание репозитория по шаблону и подключения его к MinIO c DVC и MLflow.

## Оглавление

- [Структура проекта](#структура-проекта)
  - [1. Уровень инфраструктуры](#1-уровень-инфраструктуры)
  - [2. Уровень проекта](#2-уровень-проекта)
  - [Диаграммы](#поясняющие-диаграммы)
- [Использование](#использование)
  - [Host Machine <-> DevBox](#host-machine---devbox)
  - [Первичная настройка](#первичная-настройка)
  - [Добавление проекта](#добавление-проекта)
  - [Подключение DVC](#подключение-dvc)
  - [Рабочий процесс](#рабочий-процесс)
  - [GitFix](#gitfix)
- [Полезные ссылки](#полезные-ссылки)
---

# Структура

Шаблон разделён на два концептуальных уровня: инфраструктурный и проектный. Пояснение о взаимодействии сущностей между этими уровнями - на [диаграмме](#логическая-схема-инфраструктуры-и-данных).

Технически архитектура проекта состоит из контейнеров, которые запускаются и конфигурируются набором скриптов, ключевые элементы технической реализации - на [диаграмме](#диаграмма-контейнерной-архитектуры).

## 1. Уровень инфраструктуры

Этот уровень отвечает за общую настройку среды и управление инструментами и содержит шаблоны автоматизации для:

- Запуска контейнера с S3 совместимым хранилищем данных (по умолчанию - MinIO) для версионированния данных.
- Запуска контейнера с MLflow для логирования экспериментов.
- Создание и настройку репозитория уровня проекта.

Главная цель инфраструктуры — создать универсальный каркас, который легко адаптируется под новые проекты. Если какие-то компоненты не нужны, их можно заменить или отключить. Всё сделано так, чтобы больше не заниматься этим вручную для каждого проекта.

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
<summary><b>Host Machine <-> DevBox</b></summary>

Настройка инфраструктуры и подключения к ней проекта требует выполнения команд на разных уровнях:
- на уровне хоста, т.е в `./` скопированного репозитория. 
    
    В начале блока команд, выполняемых на хосте помещена плашка - ![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)

- на уровне проекта, т.е. в `./infra/workspace/<your-repo-name>` или внутри DevBox контейнера в `/workspace/<your-repo-name>`. 

    Рекомендованный способ запуска команд на уровне проекта - подключение к контейнеру при помощи VS Code Remote Development.
    Если использовать другие способы запуска команд (docker exec, ssh), то возможно возникновение ошибки - `git dubious ownership`, которая возникает если вызов `git bash` осуществляет пользователь отличный от того, который создал локальную копию репозитория. Это ожидаемое поведение `git bash`. Если такая ошибка возникает, то можно назначить директорию проекта безопасной для вызова `git bash` от имени любого пользователя, см. [gitfix](#GitFix).

    В начале блока команд, выполняемых в DevBox помещена плашка - ![Runs on: DevBox](https://img.shields.io/badge/Runs%20on-DevBox-green)
</details> 

## Первичная настройка

![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)
- Скопируйте этот репозиторий
```bash 
git clone https://github.com/KorneevRV/DS_template_infrastructure
```
- Создайте `.env` файлы на основе шаблонов `*.env.template`, запустите контейнер MinIO и DevBox. Скрипт для выполнения этих действий:
```bash 
make init
```
- Перейдите в [web-интерфейс MinIO](http://localhost:9001/), данные для авторизации - `infra/MinIO/.env`. Создайте ключ доступа, сохраните Access Key и Secret Key. Создайте два bucket:
    - `mlflow-artifacts` - для хранение артефактов модели через MLFlow API
    - `<your-data-bucket>` - для хранения данных

## Добавление проекта

![Runs on: DevBox](https://img.shields.io/badge/Runs%20on-DevBox-green)
- Внутри DevBox создайте git-репозиторий вашего проекта в `/workspace/<your-repo>`:
```bash
git clone <your-repo>

OR

mkdir <your-repo>
cd <your-repo>
git init
```
![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)
- **Добавьте учетные данные**. Добавление осуществятся через интерактивный CLI, как правило требуется изменить:

    Созданные при [первичной настройке](#Первичная-настройка):
    - MinIO bucket name - название bucket для хранения данных
    - MinIO access key - сохраненный Access Key
    - MinIO secret key - сохраненный Secret Key
    
    Созданный на прошлом шаге
    - Repository name - имя/директория вашего локального репозитория

    Запуск интерфейс для редактирования учетных данных:

    ```bash
    make addcreds
    ```

- Запустите все контейнеры:
```bash
(cd infra && docker-compose up)
```

- **Скопируйте шаблон проекта**. При копировании шаблона:
    - В вашем локальном репозитории будет создана ветка `tempalte`
    - В ветку `template` будет скопирована вся структура (т.е все файлы кроме README.md) из [шаблона]().

    Запуск копирования шаблона:
    ```bash
    make newproject
    ```

![Runs on: DevBox](https://img.shields.io/badge/Runs%20on-DevBox-green)
- Перейдите в ветку `template`. При необходимости измените набор библиотек, установливаемых по умолчанию, заполните README,
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
![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)
- **Запустите установку библиотек для Python**. Скрипт создаст в вашем локальном репозитории виртуальное окружение при помощи `venv` и установит в него все библиотеки из файла `requirements.txt` Скрипт для запуска установки библиотек:
```bash
make install
```

## Подключение DVC
![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)

- **Запустите скрипт для подключения DVC**. Скрипт создаст ветку `dvc` в вашем локальном репозитории, выполнит инициализацию DVC, добавит директорию `/data` в отслеживаемые DVC. Скрипт для подключения DVC:
```bash
make adddvc
```
![Runs on: DevBox](https://img.shields.io/badge/Runs%20on-DevBox-green)

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
(cd infra && docker compose up)
```

- **Подсоединитесь к DevBox**

    *По умолчанию название контейнера `python-dev-container`. Рекомендуется использовать VS Code Remote Development -> Attach to running container*

![Runs on: DevBox](https://img.shields.io/badge/Runs%20on-DevBox-green)
- Модифицируйте код, версионируйте данные, артефакты и эксперименты при помощи DVC и MLFlow.

    - Веб-интрефейс MLFlow: [http://0.0.0.0:5000/](http://0.0.0.0:5000/)
    - Код для обращения к MLFlow API: 
    ```python
    mlflow.set_tracking_uri(uri='http://0.0.0.0:5000/')

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
(cd infra && docker compose down)
```

## GitFix
Рекомендованный способ запуска команд в DevBox - подключение к контейнеру при помощи VS Code Remote Development.

Если использовать другие способы запуска команд (docker exec, ssh), то возможно возникновение ошибки `git dubious ownership`, которая возникает если вызов `git bash` осуществляет пользователь отличный от того, который создал локальную копию репозитория. Это ожидаемое поведение `git bash`. Если такая ошибка возникает, то можно назначить директорию проекта безопасной для вызова `git bash` от имени любого пользователя при помощи:

![Runs on: Host Machine](https://img.shields.io/badge/Runs%20on-Host%20Machine-blue)
```
make fixgit
```
