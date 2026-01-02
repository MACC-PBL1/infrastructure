# Terraform - Infraestructura modular (dev/prod)

Estructura:

- `modules/`: módulos reutilizables (red, security groups, NAT+bastion, ALB, microservices, RDS, API Gateway)
- `environments/dev`: entorno funcional (estado **local**)
- `environments/prod`: esqueleto vacío (por ahora)

## Requisitos

- Terraform >= 1.5
- AWS credentials configuradas (AWS CLI / env vars)
- Un `key_pair_name` existente en la región (para poder hacer SSH a bastion/microservices)

## Uso (DEV)

```bash
cd environments/dev
terraform init
terraform apply
```

Probar (ejemplo):

```bash
curl "https://<api_id>.execute-api.<region>.amazonaws.com/svc1/health"
```

Destruir todo:

```bash
terraform destroy
```

## Notas importantes

- Mantengo **los mismos nombres de recursos** (nombres de bloques Terraform), pero al estar dentro de módulos, las direcciones en el state cambian a `module.<modulo>...`.
  - Si vienes de una versión “monolítica” y quieres **migrar state sin recrear**, puedes usar `terraform state mv` (o `moved {}`) para mapear los recursos antiguos a los nuevos.
  - Si tu laboratorio es efímero, lo más simple es: `terraform destroy` en el monolito y luego `terraform apply` aquí.
