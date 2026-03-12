🟦 1. START: Przygotowanie lokalne (robisz tylko raz)

Zakładam, że masz już:

    Terraform

    Azure CLI

    Ansible

    Docker

    repozytorium projektu

    działający main.tf

Jeśli tak — przechodzimy dalej.
🟩 2. URUCHOMIENIE INFRASTRUKTURY (Terraform)
2.1. Przejdź do katalogu Terraform
bash

cd ~/projekty/azure-monitoring/terraform

2.2. Inicjalizacja (robisz tylko raz)
bash

terraform init

2.3. Sprawdzenie planu
bash

terraform plan

2.4. Utworzenie infrastruktury
bash

terraform apply

Potwierdzasz:
Kod

yes

2.5. Pobranie publicznego IP
bash

terraform output public_ip

Zapisz ten adres — to Twój serwer.
🟦 3. LOGOWANIE DO VM (SSH)
3.1. Logowanie jako Ty (student)
bash

ssh student@PUBLICZNE_IP

3.2. Logowanie jako prowadzący (test)
bash

ssh tligocki@PUBLICZNE_IP

Jeśli oba działają — konfiguracja SSH jest poprawna.
🟩 4. KONFIGURACJA SYSTEMU (Ansible)
4.1. Przejdź do katalogu Ansible
bash

cd ~/projekty/azure-monitoring/ansible

4.2. Upewnij się, że inventory ma poprawne IP

Plik inventory.ini:
Kod

[vm]
PUBLICZNE_IP ansible_user=student ansible_ssh_private_key_file=~/.ssh/id_rsa

4.3. Uruchomienie playbooka
bash

ansible-playbook -i inventory.ini playbook.yml

Co się stanie:

    system zostanie zaktualizowany

    nginx zostanie zainstalowany i uruchomiony

    Docker zostanie zainstalowany

    kontener Zabbix Server zostanie uruchomiony

🟦 5. TEST DZIAŁANIA PROJEKTU
5.1. Test HTTP (nginx)

W przeglądarce:
Kod

http://PUBLICZNE_IP

Powinieneś zobaczyć stronę nginx.
5.2. Test Dockera

Zaloguj się przez SSH:
bash

ssh student@PUBLICZNE_IP

Sprawdź:
bash

docker ps

Powinieneś zobaczyć kontener:
Kod

zabbix-server

5.3. Test portu Zabbix (10051)

Lokalnie:
bash

nc -vz PUBLICZNE_IP 10051

Powinno pokazać:
Kod

succeeded

🟥 6. BEZPIECZNE WYŁĄCZENIE (żeby Azure nie naliczał kosztów)

Masz dwie opcje.
🟦 OPCJA A — Zatrzymać VM (najczęściej używana)

To zatrzymuje naliczanie kosztów CPU/RAM.
bash

az vm deallocate --resource-group rg-azure-monitoring --name vm-monitoring

Po tym:

    VM jest wyłączona

    nie płacisz za compute

    płacisz tylko za dysk (kilka groszy dziennie)

🟥 OPCJA B — Usunąć całą infrastrukturę (0 zł)

Jeśli kończysz pracę na dziś i nie chcesz ryzykować kosztów:
bash

cd ~/projekty/azure-monitoring/terraform
terraform destroy

Potwierdzasz:
Kod

yes

To usuwa:

    VM

    sieć

    IP

    dysk

    NSG

    wszystko

🟩 7. POWRÓT DO PRACY (kolejnego dnia)
7.1. Uruchom VM
bash

az vm start --resource-group rg-azure-monitoring --name vm-monitoring

7.2. Pobierz IP (jeśli się zmieniło)
bash

terraform output public_ip

7.3. Zaloguj się
bash

ssh student@PUBLICZNE_IP

I możesz kontynuować pracę.
🧭 8. PODSUMOWANIE — pełny workflow DevOps
🔵 Start pracy


        cd terraform
        terraform apply
        terraform output public_ip
        ssh student@IP

🟢 Konfiguracja


`cd ansible`
`ansible-playbook -i inventory.ini playbook.yml`

🟣 Testy

  `  http://IP`

`    docker ps`

`    nc -vz IP 10051`

🔴 Koniec pracy
Kod

`az vm deallocate --resource-group rg-azure-monitoring --name vm-monitoring`

lub

`terraform destroy`