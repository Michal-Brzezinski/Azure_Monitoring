🇬🇧 English | 🇵🇱 [Polski](README.pl.md)

### 1. Project target

What are we creating and why.


### 2. Architecture

ASCII diagram or picture.


### 3. Technologies

Terraform, Ansible, Docker, Azure.


### 4. Launch/execution instruction.

Step by step.


### 5. Catalog structure.

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



### 6. Automatzation

How does it work? Workflow: Terraform → Ansible → Docker.


### 7. Conclusions

What have we learned?