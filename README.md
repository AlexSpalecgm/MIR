# MIR

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

