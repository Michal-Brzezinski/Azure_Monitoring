🇵🇱 Polski | 🇬🇧 [English](README.md)

### 1. Cel projektu

Celem projektu jest automatyczne utworzenie i skonfigurowanie środowiska monitoringu w chmurze Microsoft Azure, z wykorzystaniem:
- **Terraform** – Infrastructure as Code (IaC), automatyczne tworzenie infrastruktury,
- **Ansible** – automatyzacja konfiguracji systemu operacyjnego,
- **Docker** – uruchomienie serwera monitoringu (Zabbix) w kontenerze.

Projekt realizowany jest w ramach zajęć akademickich i wykorzystuje subskrypcję studencką Azure.

---


### 2. Architektura

        Azure Cloud
        ├── Virtual Machine (Ubuntu 22.04)
        ├── SSH (logowanie po kluczach)
        ├── HTTP (nginx)
        ├── Docker Engine
        └── Zabbix Server (kontener)


### 3. Technologie

| Technologia | Rola |
|------------|------|
| **Terraform** | Tworzenie infrastruktury w Azure |
| **Ansible** | Konfiguracja systemu i instalacja usług |
| **Docker** | Uruchomienie Zabbixa w kontenerze |
| **Azure CLI** | Autoryzacja i zarządzanie subskrypcją |

---


### 4. Instrukcja uruchomienia

#### 1. Terraform

`cd terraform`→`terraform init`→`terraform plan`→`terraform apply`


#### 2. Ansible

`cd ansible`→`ansible-playbook -i inventory.ini playbook.yml`


### 5. Struktura katalogów

        azure-monitoring/
        │
        ├── terraform/
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── README.md
        │
        ├── ansible/
        │   ├── inventory.ini
        │   ├── playbook.yml
        │   ├── roles/
        │   │   ├── base/
        │   │   ├── docker/
        │   │   └── zabbix/
        │   └── README.md
        │
        ├── docs/
        │   ├── architecture.md
        │   ├── workflow.md
        │   └── ssh_access.md
        │
        ├── .gitignore
        ├── README.md
        └── README.pl.md



### 6. Automatyzacja

Jak działa Terraform → Ansible → Docker.

### 7. Uruchomienie/Zatrzymanie

Zatrzyamanie:

```bash 
az vm deallocate --resource-group rg-azure-monitoring --name vm-monitoring
```

Uruchomienie:

```shell
az vm start --resource-group rg-azure-monitoring --name vm-monitoring
```

Oraz po kilku sekundach:

```shell
terraform output public_ip
```

Po czym można użyć ssh

```shell
ssh student@20.234.10.32
```


### 8. Wnioski

Czego się nauczyłeś.


---

## 🔐 Dostęp SSH

VM umożliwia logowanie po kluczach SSH:
- użytkownik **student** – klucz lokalny
- użytkownik **tligocki** – klucz prowadzącego

---

## 📝 Dokumentacja

Pełna dokumentacja znajduje się w katalogu `docs/`.

---

## 👨‍💻 Autorzy
Projekt wykonany przez:  
**Michał [Twoje nazwisko]**  
W ramach zajęć z automatyzacji infrastruktury.

