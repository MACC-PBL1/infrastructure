# Infra Terraform: API Gateway → ALB → Microservicios → Aurora (Multi-AZ)

Esta práctica despliega en AWS la infraestructura:

**API Gateway (HTTP API, fuera de la VPC)** → **VPC Link** → **ALB interno (private)** → **Microservicios en EC2 (ASG + TG)** → **Aurora MySQL (1 writer + 2 readers)**

## Requisitos

- Terraform >= 1.5
- AWS CLI configurado (credenciales válidas)
- Un **Key Pair** existente en AWS (por defecto `vockey`), indicado en `terraform.tfvars`

## Estructura de archivos

- `provider.tf`: provider AWS + data sources (AZs y AMIs)
- `variables.tf`: variables del proyecto
- `terraform.tfvars`: valores del entorno
- `locals.tf`: nombres y AZs
- `network.tf`: VPC, subredes, rutas
- `security_groups.tf`: security groups (archivo separado)
- `nat_bastion.tf`: EC2 pública que hace de bastion + NAT instance
- `alb.tf`: ALB interno + listener + target groups + rules
- `microservices.tf`: launch template + ASG + política de escalado por CPU (60%)
- `apigateway.tf`: HTTP API + VPC link + integración al ALB
- `rds.tf`: Aurora cluster (3 instancias)
- `outputs.tf`: salidas útiles

## Arquitectura (según tu enunciado)

### VPC y subredes (2 AZs)

- AZ1
  - **Public subnet**: 1 EC2 `t2.micro` (NAT + Bastion)
  - **Private subnet**: microservicios (ASG multi-AZ)
- AZ2
  - **Private subnet**: microservicios (ASG multi-AZ)

### Entrada (fuera de la VPC)

- **API Gateway HTTP API** (público)
- **VPC Link** hacia subredes privadas
- **ALB interno** en subredes privadas (AZ1/AZ2)

### Microservicios

- 3 microservicios (`svc1`, `svc2`, `svc3`)
- Cada microservicio tiene:
  - 1 Target Group
  - 1 Auto Scaling Group (en **las 2 subredes privadas**)
  - `min=1`, `desired=1`
  - Política Target Tracking: **CPU objetivo = 60%**
- En las instancias se levanta un server HTTP simple en Python:
  - `/health` → 200 OK
  - cualquier otra ruta → responde con nombre del servicio y path

### Base de datos

- Aurora MySQL cluster:
  - 1 writer + 2 readers (3 instancias)
  - Subnet group en subredes privadas
  - SG permite 3306 solo desde SG de microservicios

## Cómo desplegar

1) Edita `terraform.tfvars` (muy importante: `db_master_password` y `key_pair_name`)

2) Inicializa y aplica:

```bash
terraform init
terraform plan
terraform apply
```

3) Al final verás outputs como:

- `api_gateway_url`
- `nat_bastion_public_ip`
- `aurora_writer_endpoint`

## Cómo probar

Usa el output `api_gateway_url`.

Ejemplos (desde tu máquina local):

```bash
curl "$(terraform output -raw api_gateway_url)/svc1/test"
curl "$(terraform output -raw api_gateway_url)/svc2/hello"
curl "$(terraform output -raw api_gateway_url)/svc3/health"
```

Deberías obtener respuestas tipo:

- `svc1 responding on 8081 ...`
- `ok` en `/health`

## Notas importantes (práctica)

- El **ALB es interno**: no es accesible directamente desde Internet.
- La única entrada pública es **API Gateway**.
- La NAT instance se usa para que las instancias privadas puedan hacer `apt-get update`, etc.
- Para producción real, AWS recomienda **NAT Gateway** y restringir SSH a tu IP.

## Limpieza

```bash
terraform destroy
```
