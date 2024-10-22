# MIR

![image](https://github.com/user-attachments/assets/493d6169-81da-45f4-8d47-fa30beaa9df6)



Команды для установки системы мониторинга МИР. ИСП.


RedHat Enterprise Linux VM on Hyper-V with Enhanced Session Mode.

sudo dnf install git-all
(Установка git)

sudo git clone https://github.com/EtienneBarbier/Hyper-V-RHEL-VM.git
(Требуется перенести в свой репозиторий)

https://github.com/AlexSpalecgm/MIR/blob/main/install_configure_esm_rhel.sh

cd Hyper-V-RHEL-VM

sudo chmod +x install_configure_esm_rhel.sh

sudo ./install_configure_esm_rhel.sh

In Hyper-V you need to enable the Guest services for your VM. You can find the option under : Click right on VM > settings > Management > Integrations Services > Guest services.

![image](https://github.com/user-attachments/assets/79870a64-742e-4f3e-991a-6aba8a7a6f51)

The last step is to set the EnhancedSessionTransportType to HVSocket for your VM. This can be done by executing the following command line as user in Powershell by replacing <VM_NAME> by the name of your VM. (with administrator privileges)

Set-VM "<VM_NAME>" -EnhancedSessionTransportType HVSocket

Now, you can start your VM. After a few moments, you should have the following windows prompted.

![image](https://github.com/user-attachments/assets/490a4042-f488-4e74-93ef-2c9bd8b066e6)

You can set your display settings and go to Local Resources to modify sound and clipboard settings. (optional)

![image](https://github.com/user-attachments/assets/7a9213e6-22d0-458e-9fd6-c023760f553f)

================================================

Установка docker (docker-compose)

Скачиваем конфигурационный файл для репозитория докер:

wget -P /etc/yum.repos.d/ https://download.docker.com/linux/centos/docker-ce.repo

Теперь устанавливаем docker:

sudo dnf install docker-ce docker-ce-cli

И разрешаем автозапуск сервиса и стартуем его:

sudo systemctl enable docker --now

Устанавливаем CURL:

sudo yum install curl

Задаем переменную с последней версией docker-compose скрипта:

COMVER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

Теперь скачиваем скрипт docker-compose и помещаем его в каталог /usr/bin:

sudo curl -L "https://github.com/docker/compose/releases/download/$COMVER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose

Даем права файлу на исполнение:

sudo chmod +x /usr/bin/docker-compose

Запускаем docker-compose с выводом его версии:

docker-compose --version

Этот код скачивает содержимое репозитория skl256/grafana_stack_for_docker:

sudo git clone https://github.com/skl256/grafana_stack_for_docker.git

Переходим в скаченный репозиторий

cd grafana_stack_for_docker

Создаем каталог (подкаталог):

sudo mkdir -p /mnt/common_volume/swarm/grafana/config

Создаем каталоги, используя перечисление имен:

sudo mkdir -p /mnt/common_volume/grafana/{grafana-config,grafana-data,prometheus-data,loki-data,promtail-data} 

Изменяем принадлежность  \ владельца \ доступ к файлам:

sudo chown -R $(id -u):$(id -g) {/mnt/common_volume/swarm/grafana/config,/mnt/common_volume/grafana}

Создаем файл:

sudo touch /mnt/common_volume/grafana/grafana-config/grafana.ini

Копируем все файлы из папки в необходимую директорию:

sudo cp config/* /mnt/common_volume/swarm/grafana/config/

Используя команду перемещения, переименовываем файл:

sudo mv grafana.yaml docker-compose.yaml

Поднимаем докер компос (из папки с конфигом docker-compose.yaml)

sudo docker compose up -d
