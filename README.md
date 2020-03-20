# kazhem_infra
kazhem Infra repository


# Домашние задания
## HomeWork 2: GitChatOps
Будет заполнено
## HomeWork3: Знакомство с облачной инфраструктурой.pdf
* Создана УЗ для GCP
* Создана пара ssh ключей `~/.ssh/kazhem` и публичная часть была добавлена в метаданные в Compute Engine GCP
* В Compute Engine были созданы две виртуальные машины - **bostion**, с внешним IP адресом `35.195.154.67` (и внутренним `10.132.0.2`) и **someinternalhost** только с внутренним IP адресом `10.132.0.3` (**без внешнего**)
* Для подключения **someinternalhost** необходимо сначала подключиться по **ssh** к хосту **bostion** с включенным SSH Agent Forwarding (параметр -A) и затем с него выполнить подключение по **ssh** к хосту `10.132.0.3`:
    ```
    ssh -A -i ~/.ssh/kazhem kazhem@35.195.154.67
    kazhem@bastion:~$ ssh kazhem@10.132.0.3
    kazhem@someinternalhost:~$ hostname
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
       ```
       ssh -i ~/.ssh/kazhem -J kazhem@35.195.154.67 kazhem@10.132.0.3
       kazhem@someinternalhost:~$ hostname
       someinternalhost
       ```
    * через proxycommand с перенаправлением ввода:
      ```
      ssh kazhem@10.132.0.3 -o "proxycommand ssh -W %h:%p -i ~/.ssh/kazhem kazhem@35.195.154.67"
      ```
* Для того, чтобы подключаться к **someinternalhost** через команду `ssh someinternalhost` необходимо создать файл `~/.ssh/config` добавив в него следующее содержимое:
    * Для ProxyJump:
        ```
        Host bastion
                HostName 35.195.154.67
                User kazhem
                Port 22
                IdentityFile ~/.ssh/kazhem
                ForwardAgent yes

        Host someinternalhost
                HostName 10.132.0.3
                User kazhem
                Port 22
                IdentityFile ~/.ssh/kazhem
                ProxyJump bastion
        ```
    * Для ProxyCommand:
        ```
        Host bastion
                HostName 35.195.154.67
                User kazhem
                Port 22
                IdentityFile ~/.ssh/kazhem
                ForwardAgent yes

        Host someinternalhost
                HostName 10.132.0.3
                User kazhem
                Port 22
                IdentityFile ~/.ssh/kazhem
                ProxyCommand ssh -W %h:%p bastion
        ```
 * Установлен и настроен VPN-сервер [pritunl](https://pritunl.com/)
    ```
    bastion_IP = 35.195.154.67
    someinternalhost_IP = 10.132.0.3
    ```
   * Добавлены организация и пользователь
   * Добавлен сервер
   * Добавлено правило в брэндмауэр для доступа к внутренней сети
   * Создано доменное имя c помощью [sslip.io](https://sslip.io/): **35.195.154.67.sslip.io**, которое резолвитсяв IP 35.195.154.67. Домен был подписан сертификатом [LetsEncrypt]("https://letsencrypt.org/") с помощью [Certbot](https://certbot.eff.org/)
   * В нстройках pritunl (веб) был указан сертификат LetsEncrypt
   * Веб-интерфейс доступен по адресу https://35.195.154.67.sslip.io/ с валидным сертификатом
