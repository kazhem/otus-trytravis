# kazhem_infra
Kazhemskiy Mikhail OTUS-DevOps-2020-02 Infra repository


# Домашние задания
## HomeWork 2: GitChatOps
* Создан шаблон PR
* Создана интеграция с TravisCI
```bash
 travis encrypt "devops-team-otus:<ваш_токен>#<имя_вашего_канала>" --add notifications.slack.rooms --com
```
* Создана интеграция с чатом для репозитория
* Создана интеграция с чатом для TravisCI
* Отработаны навыки работы с GIT
## HomeWork3: Знакомство с облачной инфраструктурой

~~~
bastion_IP = 35.195.154.67
someinternalhost_IP = 10.132.0.3
~~~

* Создана УЗ для GCP
* Создана пара ssh ключей `~/.ssh/appuser` и публичная часть была добавлена в метаданные в Compute Engine GCP
* В Compute Engine были созданы две виртуальные машины - **bostion**, с внешним IP адресом `35.195.154.67` (и внутренним `10.132.0.2`) и **someinternalhost** только с внутренним IP адресом `10.132.0.3` (**без внешнего**)
* Для подключения **someinternalhost** необходимо сначала подключиться по **ssh** к хосту **bostion** с включенным SSH Agent Forwarding (параметр -A) и затем с него выполнить подключение по **ssh** к хосту `10.132.0.3`:
    ```bash
    ssh -A -i ~/.ssh/appuser appuser@35.195.154.67
    appuser@bastion:~$ ssh appuser@10.132.0.3
    appuser@someinternalhost:~$ hostname
    someinternalhost
    ```
 * Для подключения одной командой, минуя bastion хост можно:
    * добавить параметр `-J`  команде ssh:
        ```
        -J [user@]host[:port]
             Connect to the target host by first making a ssh connection to
             the jump host and then establishing a TCP forwarding to the ulti‐
             mate destination from there.  Multiple jump hops may be specified
             separated by comma characters.  This is a shortcut to specify a
             ProxyJump configuration directive.
        ```
       ```bash
       ssh -i ~/.ssh/appuser -J appuser@35.195.154.67 appuser@10.132.0.3
       appuser@someinternalhost:~$ hostname
       someinternalhost
       ```
    * через proxycommand с перенаправлением ввода:
      ```bash
      ssh appuser@10.132.0.3 -o "proxycommand ssh -W %h:%p -i ~/.ssh/appuser appuser@35.195.154.67"
      ```
* Для того, чтобы подключаться к **someinternalhost** через команду `ssh someinternalhost` необходимо создать файл `~/.ssh/config` добавив в него следующее содержимое:
    * Для ProxyJump:
        ```
        Host bastion
                HostName 35.195.154.67
                User appuser
                Port 22
                IdentityFile ~/.ssh/appuser
                ForwardAgent yes

        Host someinternalhost
                HostName 10.132.0.3
                User appuser
                Port 22
                IdentityFile ~/.ssh/appuser
                ProxyJump bastion
        ```
    * Для ProxyCommand:
        ```
        Host bastion
                HostName 35.195.154.67
                User appuser
                Port 22
                IdentityFile ~/.ssh/appuser
                ForwardAgent yes

        Host someinternalhost
                HostName 10.132.0.3
                User appuser
                Port 22
                IdentityFile ~/.ssh/appuser
                ProxyCommand ssh -W %h:%p bastion
        ```
 * Установлен и настроен VPN-сервер [pritunl](https://pritunl.com/)
   * Добавлены организация и пользователь
   * Добавлен сервер
   * Добавлено правило в брэндмауэр для доступа к внутренней сети
   * Создано доменное имя c помощью [sslip.io](https://sslip.io/): **35.195.154.67.sslip.io**, которое резолвитсяв IP 35.195.154.67. Домен был подписан сертификатом [LetsEncrypt]("https://letsencrypt.org/") с помощью [Certbot](https://certbot.eff.org/)
   * В нстройках pritunl (веб) был указан сертификат LetsEncrypt
   * Веб-интерфейс доступен по адресу https://35.195.154.67.sslip.io/ с валидным сертификатом

## HomeWork4: Основные сервисы Google Cloud Platform (GCP)
~~~

testapp_IP = 35.189.238.97
testapp_port = 9292

~~~
* Сделана установка и настройка [gcloud](https://cloud.google.com/sdk/docs/)
* С помощью утилиты gcloud была создана тестовая ВМ c названием **reddit-app**
    ```
    gcloud compute instances create reddit-app\
      --boot-disk-size=10GB \
      --image-family ubuntu-1604-lts \
      --image-project=ubuntu-os-cloud \
      --machine-type=g1-small \
      --tags puma-server \
      --restart-on-failure
    ```
* На ВМ были установлены Ruby, MongoDB а также Ruby приложение из указнного репозитория
* В настройка GCP было добавлено правило фаервола для доступа к порту `9292` приложения
* Команды по настройке системы и деплоя приложения были завернуты в скрипты
    * [install_ruby.sh](install_ruby.sh) - установка Ruby
    * [install_mongodb.sh](install_mongodb.sh) - установка MongoDB
    * [deploy.sh](deploy.sh)  - скачивание и запуск приложения
* Для настройки одной командой вышепеечисленные команды были добавлены в файл [startup_script.sh](startup_script.sh)
* Данный файл был добавлен в параметры gloud так, что при создании ВМ запускается cкрипт, который зустаноавливает зависимости и запускает нужное приложении (параметр `--metadata-from-file startup-script=<path_to_local_file>`):
    ```
    gcloud compute instances create reddit-app\
      --boot-disk-size=10GB \
      --image-family ubuntu-1604-lts \
      --image-project=ubuntu-os-cloud \
      --machine-type=g1-small \
      --tags puma-server \
      --restart-on-failure\
      --metadata-from-file startup-script=./startup_script.sh
    ```
 * Удалено, а затем добавлено через утилиту gcloud правило фаервола **default-puma-server**
    ```
    gcloud compute firewall-rules create default-puma-server \
      --allow tcp:9292 \
      --target-tags=puma-server
    ```
## HomeWork5: Модели управления инфраструктурой Packer
* Произведена установка [Packer](https://www.packer.io/downloads.html) на локальную машину
* Установлен и авторизовн **Application Default Credentials** (ADC) для того, чтобы Packer мог управлять ресурсами GCP через API вызовы
  ```
  gcloud auth application-default login
  ```
* Создан Packer template [ubuntu16.json](packer/ubuntu16.json)
    * Настроены **builders**, отвечающий за создание ВИ для билда
    * Настроены **provisioners** с типо _shell_, устанавливающие MongoDB и Ruby с помощью скриптов [install_mongodb.sh](packer/scripts/install_mongodb.sh) и [install_ruby.sh](packer/scripts/install_ruby.sh)
* [ubuntu16.json](packer/ubuntu16.json) проверен на наличие ошибок в синтакисисе
   ```
   packer validate ./ubuntu16.json
   ```
* Собран образ из шаблона [ubuntu16.json](packer/ubuntu16.json)
   ```
   packer build ubuntu16.json
   ```
* Создана ВМ через GUI GCP из собранного раннее образа
* Вручную, через SSH, установлен и запущен puma server
* Добавлены пользовательские переменные, обязателные вынесены в файл variables.json
    ```
    "variables": {
        "project_id": null,
        "source_image_family": null,
        "machine_type": "f1-micro",
        "ssh_username": "appuser"
    },
    ```
* Запущена сборка образа с пользвательскими переменными
  ```
  packer build --var-file variables.json ubuntu16.json
  ```
* Добавлены новые поля в builders:
  ```
  "image_description": "Reddit base app image with mongo and redis installed",
   "disk_size": 10,
   "disk_type": "pd-standard",
   "network": "default",
   "tags": ["puma-server"],
  ```
 ### Задание со *
 * Создан [puma.service](packer/files/puma.service) файл для автоматического запуска приложения
 * Создан файл [startup_script.sh](packer/scripts/startup_script.sh) для установки и настройки сервиса для старта прложения при запуске ВМ
 * Создан конфиг [immutable.json](packer/immutable.json) для packer, создающий образ семейства reddit-full с bake образом приложения
 * Создан файл [create-reddit-vm.sh](config-scripts/create-reddit-vm.sh),запускающий команду gloud, создающую ВМ на основе образа reddit-full.

## Homework6: Знакомство с Terraform
### Основное задание
* Установлен [Terraform](https://www.terraform.io/downloads.html)
  * [Getting Started Guide](https://www.terraform.io/docs/providers/google/guides/getting_started.html)
* Cоздан файл [main.tf](terrafiorm/main.tf), где были указазаны основные параметры подключения: версия terraform, provider (google), ID проекта и регион.
* Инициализоровна terraform:
  ```
  terraform init
  ```
* В файл [main.tf](terrafiorm/main.tf) добавлен ресурс [google_compute_instance](https://www.terraform.io/docs/providers/google/r/compute_instance.html) а так же boot_disk - образ, с которого создавать VM
* Основные команды:
  * `terraform plan` - запланировать изменения (посмотреть, что будет сделано при применении)
  * `terraform apply --auto-approve` - применить изменения с автоподтверждением
  * `terraform show` - показать текущее состаяние TF. К примерну показать внешний IP: `terraform show | grep nat_ip`
  * `terraform destroy` - удалить все созданные ресурсы
  * `terraform fmt` - отформатировать файлы *.tf до "правильного" вида (синтаксис)
* Добавлен SSH-ключ для подключения в metadata **инстанса**
* Добавлен файл [outputs.tf](terraform/outputs.tf) для создания выхоных переменных
* Добавлен ресурс *google_compute_firewall* для добавления правил фаервола
* Инстансу добавлен сетевые *tags* для применения правил фаервола
* Добавлены [Provisioners](https://www.terraform.io/docs/provisioners/index.html), которые вызываются только в момент **создания/удаления** ресурса
* В provisioners также добавлен файл *Systemd Unit service* [puma.service](terraform/files/puma.service) для автоматического запуска приожения reddit-app и скрипт деплоя [deploy.sh](terraform/files/deploy.sh)
* Добавлен файл с описанием  input переменных [variables.tf](terraform/variables.tf) и заменены в main.tf (var.{ИМЯ ПЕРЕМЕННОЙ})
  * Значения переменных вынесены в файл *terraform.tfvars*, который не индексирусется git-ом

### Самостоятельные задания
* Добавлены переменные зоны ресурса и приватного ключа для подключения провиженоров
* Отформатированы файлы настроек для паривльного вида `terraform fmt`
* Добавлен пример файла input переменных [terraform.tfvars.example](./terraform/terraform.tfvars.example)

### Задание со *
* Добавлен [ресурс](https://www.terraform.io/docs/providers/google/r/compute_project_metadata_item.html) `google_compute_project_metadata_item` для того, чтобы добавить ключи пользователя в метаданные проекта (***важно** - данные в секции EOF должны обязательно начинаться с самого начала строки - лишние пробелы GCP не отрезает и работает некорректно*):
  ```
  resource "google_compute_project_metadata_item" "ssh_keys" {
    key = "ssh-keys"
    value = <<EOF
  appuser1:${file(var.public_key_path)}
  appuser2:${file(var.appuser2_public_key_path)}
  EOF
  }
  ```
* Если добавить ssh ключ через веб интерфейс и это не будет соответсвовать настройкам терраформа, то при `terraform apply` такой ключ будет удален.

### Задание с **
При разработке использовались следующие ресурсы из описания [документации](https://cloud.google.com/load-balancing/docs/https/):


* Создан файл `lb.tf`, в котором описаны следующие сущности:
  * [google_compute_instance_group](https://www.terraform.io/docs/providers/google/r/compute_instance_group.html) со списком инстансов ВМ с запущенным приложением (1 экземпляр)
  * [google_compute_health_check](https://www.terraform.io/docs/providers/google/r/compute_health_check.html) для проверки доступности приложения на экземпляре ВМ
  * [google_compute_backend_service](https://www.terraform.io/docs/providers/google/r/compute_backend_service.html) со ссылкой на группы экземпляров ВМ (в данном случае на 1 группу), а так же со ссылкой на google_compute_health_check
  * [google_compute_url_map](https://www.terraform.io/docs/providers/google/r/compute_url_map.html) с описанием запросу к какому url на какой backend_service отправлять (в нашем случае все запросы ко всем url отправляются на 1 сервис)
  * [google_compute_target_http_proxy](https://www.terraform.io/docs/providers/google/r/compute_target_http_proxy.html) для проксирования http/https соединений к url_map
  * [google_compute_global_forwarding_rule](https://www.terraform.io/docs/providers/google/d/datasource_compute_forwarding_rule.html) для перенаправления ip4/ip6 трафика (для каждого типа трафика должно быть своё правило) на target_http_proxy (в нашем случае только ip4)
* *Backend service долго стартует*
* Был добавлен второй инстанс reddit-app (app2) в instance_group
  * При отключении puma сервера видно, что по health-check доступен только один из двух инстансов. При этом приложение через LB остается доступным.
  * При добавление нового инстанса копированием создается избыточное количество кода
* Для добавления N одинкаовых инстаносов добавлен параметр `count` в `google_compute_instance`. Сама переменая задается в `variables.tf`

## Homework7: Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform

* Заимпортирована текущие настройки terraform (ssh firewall rules)
  ```
  terraform import google_compute_firewall.firewall_ssh default-allow-ssh
  ```
* Добавлен ресурс [google_compute_address](https://www.terraform.io/docs/providers/google/r/compute_address.html) для того, чтобы иметь возможность обращаться к адресу инстанса из других ресурсов
  ```
  resource "google_compute_address" "app_ip" {
  name = "reddit-app-ip"
  }
  ```
* Для того чтобы использовать адрес внутри ресурса инстанса необходимо сослаться на него следующим образом (внутри инстанса ВМ). При этом ресурс ВМ становится зависимым от  ресурса `google_compute_address` и при создании инфорстрактуры создается после него.
  ```
  network_interface {
    network = "default"
    access_config {
    nat_ip = google_compute_address.app_ip.address
    }
  }
  ```
* В директории packer созданы шаблоны [db.json](packer/db.json) и [app.json](packer/app.json) а затем по ним созданы образы семейста `reddit-db-base` и `reddit-app-base` соотвественном. На первом установлена БД MongoDB, на втором - Ruby.
* Файл [main.tf](terraform/main.tf) разбит на несколько файлов, так, что в нем остался только описание версии тераформа и описание провайдера.
  * Созан файл [db.tf](terraform/db.tf) описывающий ВМ для БД
  * Созан файл [app.tf](terraform/app.tf) описывающий  ВМ для Reddit app
  * Создан файл [vpc.tf](terraform/vpc.tf) описывающие правила фаервола
* Созадны модули `db` и `app`. Описанные выше файлы `db.tf` и `app.tf` перенесены в эти модули.
  * После указание модулей в основном файле [main.tf](terraform/main.tf) необходимо подргрузить модули:
  ```
  terraform get
  ```
### Самостоятельное задание
* Добавлен модуль `vpc` (*переде применением не забыть заимпортить существующее правило фаервола*) по аналогии с модулями `db` и `app`
* Добавлена переменная `source_ranges` для установки IP адресов с которых будет возможен доступ по SSH и которая позволяет задавать ее при вызове модуля:
  ```
  #vpc/veriables.json
  variable source_ranges {
    description = "Allowed IP addresses"
    default = ["0.0.0.0/0"]
  }
  ```
  ```
  #main.tf
  module "vpc" {
    source          = "./modules/vpc"
    source_ranges = ["0.0.0.0/0"]
  }
  ```
  * Протестировано измениние этой переменный на свой IP (/32), а также на IP, отличный от него. Во втором случае доступ по SSH к машинам закрывется.

* В дериктории `terraform` добавлены папки `stage` и `prod`, каждая с набором файлов .tf для запуска инфаструктуры. Испульзуется одни и те же модули, но с разными параметрами (переиспользование). *При запуске терраформа **из новых папок** необходимо заного инициализировать терраформ*: `terraform init`
* Рассмотрены модули для google в [regisry HashiCorp](https://registry.terraform.io/browse/modules?provider=google)
* Добавлен модуль [storage-bucket](https://registry.terraform.io/modules/SweetOps/storage-bucket/google/0.3.1) и проверено, что создан бакет

### Задание со *
* В деррикториях stage и prod добвлен файл `backend.tf`, который описывает подключение удаленного стораджа [gcs](https://www.terraform.io/docs/backends/types/gcs.html) для хранения стейта.
  * При применении конфигурации терраформ больше не хранит локально файл `terraform.tfstate`
  * Одновременный запуск терраформа из двух дирректорий выдал ошибку, т.к. создаются одни и те же ресурсы.

### Задание с **
* Настроены provisioners для работы из модулей:
  * Необходимо было через переменные окружения передать `DATABASE_URL`. Было сделано через provisioner file с помощью атрибута `content`, который может записывать строку в файл:
  * Далее Unit service подкгружает переменные окружения из файла
  * Помимо прочего необходимо было сделать так, чтобы MongoDB поднималась не локалхосте, а, как минимум на 0.0.0.0. Поэтому при сборке образа с packer добалено изменение конфига mongod

## Homework8: Управление конфигурацией. Знакомство с Ansible
* Установлен [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* Создан [inventory.yml](ansible/inventory.yml) файл ([docs](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html))
* Протестирована работа модулей `shell`, `command`, `service`, `systemd` и сделан вывод о том, что использование специальных модулей для выполениня определенных команд (`systemd`, `service`) дают больше возможностей для дальнейшего использования вывода этих команд.
* Создан playbook [clone.yml](ansible/clone.yml), который использует модуль `git` для клонирования репозитория. Если при запуске плейбука директория после клонирования гита изменилась - ансибл пишет `changed`.
  ```
  ansible-playbook clone.yml

  PLAY [Clone] ***************************************************************************************

  TASK [Gathering Facts] *****************************************************************************
  ok: [appserver]

  TASK [Clone repo] **********************************************************************************
  changed: [appserver]

  PLAY RECAP *****************************************************************************************
  appserver                  : ok=2    changed=1    unreachable=0    failed=0
  ```
### Задание со *
* Создан файл inventory.json в [формате](https://medium.com/@Nklya/динамическое-инвентори-в-ansible-9ee880d540d6) динмического инвентори. Создан из существуего файла inventory.yml (или ini).
  ```
  ansible-inventory --list > inventory.json
  ```
  *  Данный способ не совсем корректен, т.к. динамичский инвентори генерируется обычно из каких либо внешних источников. К примерну его можно сгенерировать с помощью плагина [gcp_compute](https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html#gce-dynamic-inventory), который собирет информацию о машинах в GCP (не используется в силу ограничения задания)
    ```
    # ansible-inventory --list  -i inventory.gcp.yml
    {
    "_meta": {
        "hostvars": {
            "35.195.204.42": {
                "canIpForward": false,
                "cpuPlatform": "Intel Haswell",
                "creationTimestamp": "2020-04-13T00:28:15.683-07:00",
                "deletionProtection": false,
                "disks": [
                    {
                        "autoDelete": true,
                        "boot": true,
                        "deviceName": "persistent-disk-0
      ...
    ```
* Создан python скрипт `json_inventory.py`, который вовзращает содержимое json-инвентори по параметру `--list` и данные хоста с параметром `--host`.
* Для того, чтобы использовать данный скрипт в качестве источника inventory по умолчаню, его можно прописать в `ansible.cfg` в качество значения ключа `inventory`:
  ```
  [defaults]
  inventory = ./json_inventory.py
  ...
  ```
* Вышеуказанный файл-плагин `inventory.gcp.yml` также можно указать в качестве инвентори, и тогда ansible будет динамически знать о вашей инфраструктуре GCP.
* Команда `ansible all -m ping` выполнена успешно
