# ============================
# CONFIGURACIÓN
# ============================

VENV=.venv
ANSIBLE=$(VENV)/bin/ansible-playbook
ANSIBLE_BIN=$(VENV)/bin/ansible

INVENTORY_STATIC=inventory/dev/hosts.ini
INVENTORY_DYNAMIC=inventory/dev/aws_ec2.yml

ANSIBLE_FLAGS=-i $(INVENTORY_STATIC) -i $(INVENTORY_DYNAMIC)

PB_NAT=playbooks/nat_bastion.yml
PB_ZEEK=playbooks/zeek_logging.yml
PB_HARDENING=playbooks/hardening.yml


# ============================
# TARGETS
# ============================

.PHONY: help nat zeek hardening deploy ping inventory

help:
	@echo ""
	@echo "Targets disponibles:"
	@echo "  make nat        -> Configura NAT + Bastion"
	@echo "  make zeek       -> Instala Zeek + Fluent Bit"
	@echo "  make hardening  -> Hardening microservicios"
	@echo "  make deploy     -> Ejecuta TODO en orden"
	@echo "  make ping       -> Ping a todos los hosts"
	@echo "  make inventory  -> Ver inventario dinámico"
	@echo ""

# ============================
# EJECUCIÓN INDIVIDUAL
# ============================

nat:
	$(ANSIBLE) -i $(INVENTORY_STATIC) $(PB_NAT)

zeek:
	$(ANSIBLE) -i $(INVENTORY_STATIC) $(PB_ZEEK)

hardening:
	$(ANSIBLE) $(ANSIBLE_FLAGS) $(PB_HARDENING)

# ============================
# EJECUCIÓN COMPLETA
# ============================

deploy: nat zeek hardening
	@echo ""
	@echo "✅ Despliegue completo finalizado"
	@echo ""

# ============================
# UTILIDADES
# ============================

ping:
	$(ANSIBLE_BIN) $(ANSIBLE_FLAGS) all -m ping

inventory:
	$(ANSIBLE_BIN) -i $(INVENTORY_DYNAMIC) --graph