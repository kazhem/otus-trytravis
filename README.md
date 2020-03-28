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
