# Infrastructure as Code: AWS Architecture and Deployment Guide

## Table of Contents

1. [Infrastructure Overview](#infrastructure-overview)
2. [Terraform Architecture](#terraform-architecture)
3. [Ansible Configuration Management](#ansible-configuration-management)
4. [Design Decisions and Rationale](#design-decisions-and-rationale)
5. [Best Practices](#best-practices)
6. [Usage and Maintenance](#usage-and-maintenance)
7. [File Structure](#file-structure)

---

## Infrastructure Overview

### Purpose

The Infrastructure folder contains a comprehensive, production-ready Infrastructure as Code (IaC) implementation for deploying and managing AWS resources. This codebase integrates Terraform for resource provisioning with Ansible for post-deployment configuration management, creating a complete lifecycle automation solution for AWS cloud infrastructure.

### High-Level Architecture

The infrastructure consists of three primary components:

- **Terraform Modular VPC1**: A multi-environment Terraform implementation featuring complex networking, compute, serverless, and data pipeline components
- **Terraform Modular VPC2**: A development-focused VPC with honeypot deployments for security research and threat detection
- **Terraform Production**: A streamlined production VPC with bastion hosts, load balancing, microservices, and relational databases
- **Ansible Configuration Management**: Post-provisioning automation for system hardening, security tool deployment, and application configuration

The architecture follows a hub-and-spoke VPC peering model, allowing secure communication between isolated network environments while maintaining clear separation of concerns. Terraform provisions the infrastructure resources, while Ansible configures operating systems, deploys applications, and implements security controls.

---

## Terraform Architecture

### Overview of Terraform Structure

The Terraform codebase is organized into three distinct deployment architectures, each serving different purposes within the overall infrastructure:

#### **Terraform Modular VPC1: Multi-Environment Platform**

**Purpose**: This is the foundational platform infrastructure designed for scalability and high availability. It serves as a template for deploying complex, production-grade cloud environments.

**Key Characteristics**:
- Environment-based separation (dev, prod)
- Lambda packaging and deployment
- Advanced networking with API gateways
- Data streaming pipelines (Firehose)
- Comprehensive security implementations
- Observability stack (Grafana integration)

**Modules Available**:
- **network**: Core VPC, subnets, routing, and Internet/NAT gateways
- **security_groups**: Granular security policies
- **alb**: Application Load Balancer for traffic distribution
- **api_gateway**: AWS API Gateway for serverless APIs
- **lambda**: Function packaging and deployment with VPC integration
- **rds**: Relational database provisioning
- **s3**: Object storage with lifecycle policies
- **kms**: Key management and encryption
- **secrets**: AWS Secrets Manager integration
- **firehose**: Data delivery streams to S3
- **microservices**: Microservice architecture patterns
- **nat_bastion**: Bastion hosts and NAT gateway configurations
- **grafana**: Observability dashboards
- **vpc_peering**: VPC peering connections

---

#### **Terraform Modular VPC2: Development and Honeypot Infrastructure**

**Purpose**: This VPC is specifically designed for security research, threat detection, and development workloads. It demonstrates honeypot deployment strategies and dynamic inventory management for Ansible.

**Architecture Overview**:

The infrastructure is organized into three deployment layers:

1. **Network Layer (01-network)**
   - Provisions VPC with CIDR block isolation
   - Creates 1 public subnet (bastion/NAT access)
   - Creates 2 private subnets (application workloads)
   - Configures Internet Gateway for public subnet routing
   - Deploys NAT Gateway for private subnet egress
   - Establishes public and private route tables
   - Manages Elastic IPs for NAT gateway static addressing

2. **Peering Layer (02-peering)**
   - Accepts VPC peering connections from other VPCs
   - Configures route tables for cross-VPC communication
   - Enables bidirectional routing between peered VPCs
   - Uses remote state references for dynamic configuration

3. **Platform Layer (03-platform)**
   - Deploys security groups with rule hierarchies
   - Provisions EC2 instances for honeypot deployment (Cowrie SSH, Dionaea)
   - Allocates Elastic IPs for honeypot static addressing
   - Associates Elastic IPs with honeypot instances
   - Demonstrates dynamic inventory for Ansible integration

**Key Modules**:
- **vpc**: VPC provisioning with multi-AZ support
- **ec2**: Instance deployment with tagging strategies
- **security**: Security group management with least-privilege rules
- **dynamodb**: NoSQL database for honeypot metrics
- **kinesis_firehose**: Log streaming to S3
- **s3**: Centralized logging and data storage

**State Management**: Each layer maintains separate Terraform state files, allowing independent scaling and reduced blast radius for changes. Later layers reference earlier layers' state using remote state data sources.

---

#### **Terraform Production: Streamlined Production Environment**

**Purpose**: A simplified, production-grade VPC optimized for real-world application deployment with bastion access, load balancing, and database resilience.

**Architecture Components**:

- **VPC and Networking**:
  - Single VPC with multiple subnets across 2 availability zones
  - Public subnet (bastion host access)
  - Private subnets (application tier)
  - Internet Gateway for public internet access
  - NAT Gateway for private subnet egress

- **Compute**:
  - Bastion host in public subnet (gateway for SSH access)
  - HAProxy load balancer in public subnet (traffic distribution)
  - Microservices in private subnets (Consul, RabbitMQ, Auth, App services)

- **Data**:
  - Multi-AZ RDS database with automated backups
  - Subnet groups for database placement
  - Storage encryption at rest
  - 7-day backup retention

- **Security**:
  - Granular security groups per tier
  - Least-privilege ingress rules
  - Security group outputs for Ansible integration

**Module Structure**:
- **vpc**: Network provisioning
- **security_groups**: Tiered security policies
- **bastion**: Jump host for secure access
- **haproxy**: Load balancing and traffic distribution
- **microservices**: Application tier provisioning
- **rds**: Production database

---

### Terraform Modularization Strategy

All three Terraform implementations follow a consistent modularization pattern that promotes reusability, maintainability, and scalability.

#### **Module Structure Convention**

Each module follows a standardized layout:

```
module-name/
├── main.tf          # Core resource definitions
├── variables.tf     # Input variable declarations
└── outputs.tf       # Output values for consumption
```

This convention ensures consistency across the codebase and makes module behavior predictable.

#### **Variable Management**

Variables are organized into logical groups:

- **Naming conventions**: `name_prefix`, `project_name` for consistent resource identification
- **Networking**: CIDR blocks, subnet configurations, availability zones
- **Compute**: Instance types, AMI IDs, key pair references
- **Database**: Credentials, storage allocation, backup policies
- **Security**: SSH access controls, security group configurations

Variables are typically declared at the environment level (dev, prod) and passed to modules, enabling reuse across different deployments without code duplication.

#### **Output Strategy**

Modules expose outputs for:

- **Resource identifiers**: VPC IDs, subnet IDs, security group IDs
- **Connection details**: Endpoints, hostnames, ports
- **State references**: For consumption by other stacks or Ansible

This output-driven architecture allows later infrastructure layers to discover resources provisioned by earlier layers without hardcoding values.

#### **Remote State References**

Terraform modular VPC2 demonstrates advanced state management:

```hcl
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01-network/terraform.tfstate"
  }
}
```

This pattern enables:
- Separation of concerns (independent layer deployment)
- Reduced deployment blast radius
- Ability to independently scale components
- Clear dependency documentation

#### **Why Multiple Modular VPCs?**

The infrastructure is split into multiple VPCs for strategic reasons:

1. **Environment Isolation**: Development, production, and security research environments are isolated network-wise
2. **Scalability**: Each VPC can scale independently without affecting others
3. **Security Boundaries**: Network segmentation implements defense-in-depth
4. **Blast Radius Reduction**: Issues in one VPC don't affect others
5. **Team Autonomy**: Different teams can manage different VPCs independently
6. **Cost Attribution**: Infrastructure costs can be tracked per environment
7. **Compliance**: Sensitive workloads (honeypots, production) are in separate networks
8. **VPC Peering**: Controlled inter-VPC communication through explicit peering connections

---

### AWS Services Integration

The Terraform implementations provision and manage the following AWS services:

#### **Networking Services**
- **VPC**: Virtual network isolated in AWS
- **Subnets**: Network segments with specific routing
- **Internet Gateway**: Public internet connectivity
- **NAT Gateway**: Private subnet egress via public IP
- **VPC Peering**: Inter-VPC communication
- **Route Tables**: Traffic routing policies
- **Elastic IPs**: Static public addresses
- **Security Groups**: Virtual firewalls with stateful rules

#### **Compute Services**
- **EC2 Instances**: Virtual machines for bastion, microservices, honeypots
- **Auto Scaling Groups**: Dynamic instance scaling (in modules)
- **IAM Roles and Policies**: Identity and access management

#### **Data Services**
- **RDS**: Managed relational databases with Multi-AZ
- **DynamoDB**: NoSQL database for metrics/logs
- **S3**: Object storage for logs and Lambda packages
- **Kinesis Firehose**: Managed log delivery to S3

#### **Serverless Services**
- **Lambda**: Functions for event-driven workloads
- **API Gateway**: RESTful API endpoints
- **CloudWatch Logs**: Centralized log aggregation

#### **Security Services**
- **KMS**: Key management for encryption
- **Secrets Manager**: Credential storage and rotation
- **CloudWatch**: Monitoring and alerting

---

### Terraform State Management

The infrastructure uses local state files for each deployment layer:

- **State File Location**: `terraform.tfstate` in each environment directory
- **Backup**: `terraform.tfstate.backup` for recovery
- **Lock File**: `.terraform.lock.hcl` for provider version pinning

**State File Considerations**:
- State files contain sensitive information (credentials, private IPs)
- State files must never be committed to version control (included in `.gitignore`)
- For production, migrate to remote state (S3 + DynamoDB) with encryption and locking
- Remote state enables team collaboration with automatic locking to prevent concurrent modifications

---

## Ansible Configuration Management

### Role of Ansible in Infrastructure Lifecycle

Ansible operates as the post-provisioning orchestration layer, executing after Terraform completes infrastructure deployment. It transforms raw compute resources into configured systems ready for application workloads.

### Core Responsibilities

Ansible is responsible for:

#### **1. System Hardening and Security**
- Applies hardening_base role: SSH key-based authentication, disables root login, configures firewall rules
- Installs fail2ban for intrusion prevention
- Updates system packages to patch vulnerabilities
- Configures sysctl for network security parameters

#### **2. Security Tool Deployment**
- **Zeek**: Network monitoring and intrusion detection
- **Fluent Bit**: Log collection and forwarding
- **Honeypots**: SSH (Cowrie) and service honeypots (Dionaea)

#### **3. Infrastructure-Specific Configuration**
- **NAT/Bastion**: Network address translation, jump host setup
- **Microservices**: Service discovery (Consul), message queue (RabbitMQ), authentication service
- **Application Setup**: Custom application configuration, service registration

#### **4. Monitoring and Observability**
- Deploys logging agents (Fluent Bit)
- Configures centralized logging to Kinesis Firehose
- Sets up metric collection for CloudWatch

### Ansible Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── Makefile                 # Deployment automation
├── inventory/
│   └── dev/
│       ├── aws_ec2.yml      # Dynamic AWS inventory plugin
│       ├── hosts.ini        # Static inventory
│       └── group_vars/      # Host group variables
├── playbooks/               # Deployment orchestration
│   ├── nat_bastion.yml      # NAT and bastion setup
│   ├── zeek_logging.yml     # Network monitoring
│   ├── hardening.yml        # System hardening
│   └── honeypots.yml        # Honeypot deployment
└── roles/                   # Reusable configuration components
    ├── common/              # Base system configuration
    ├── hardening_base/      # Security hardening
    ├── fail2ban/            # Intrusion prevention
    ├── nat_bastion/         # NAT and bastion setup
    ├── zeek/                # Network IDS
    ├── fluentbit/           # Log forwarding
    ├── fluentbit-honeypots/ # Honeypot-specific logging
    ├── cowrie/              # SSH honeypot
    └── dionaea/             # Service honeypot
```

### Inventory Management

#### **Static Inventory** (`hosts.ini`)
Defines manually specified hosts and groups:

```ini
[nat_bastion]
44.197.93.28 ansible_user=admin ansible_ssh_private_key_file=~/.ssh/labsuser.pem
```

#### **Dynamic Inventory** (`aws_ec2.yml`)
Automatically discovers AWS EC2 instances using tags and filters:

```yaml
plugin: aws_ec2
regions:
  - us-east-1
filters:
  tag:Environment: dev
compose:
  ansible_host: public_ip_address
```

The dynamic inventory approach eliminates manual host list maintenance and automatically includes newly provisioned instances.

### Playbook Architecture

Playbooks are organized by functional domain:

#### **nat_bastion.yml**: Gateway Infrastructure
Applies to NAT/Bastion hosts with roles:
- common: Base system tools
- nat_bastion: NAT configuration
- hardening_base: OS-level hardening
- fail2ban: Attack prevention

#### **zeek_logging.yml**: Network Monitoring
Applies to bastion hosts with roles:
- common: Base system
- zeek: Network IDS deployment
- fluentbit: Log shipping

#### **hardening.yml**: Microservices Hardening
Applies to microservice hosts:
- common: Base system
- hardening_base: Security hardening

#### **honeypots.yml**: Honeypot Deployment
Applies to honeypot hosts:
- cowrie: SSH honeypot
- dionaea: Service honeypot
- fluentbit-honeypots: Honeypot-specific logging

### Role-Based Configuration

Each role encapsulates related tasks:

- **tasks/**: Main configuration logic
- **handlers/**: Event-driven service restarts
- **defaults/**: Default variable values
- **files/**: Static files (configs, scripts)
- **templates/**: Jinja2 templates for dynamic configuration

This structure promotes reusability—a single role can be applied across multiple playbooks and hosts.

### Integration with Terraform Outputs

The Terraform deployment produces outputs (VPC IDs, security group IDs, instance IPs) that Ansible consumes:

1. Terraform provisions resources and outputs identifiers
2. AWS EC2 dynamic inventory plugin discovers instances
3. Ansible groups hosts by tags applied during Terraform provisioning
4. Playbooks target specific groups and apply roles

---

## Design Decisions and Rationale

### 1. Infrastructure as Code Philosophy

**Decision**: Use Terraform for provisioning and Ansible for configuration management

**Rationale**:
- **Declarative Infrastructure**: Define desired state rather than imperative steps
- **Version Control**: Infrastructure changes are tracked like code
- **Reproducibility**: Identical deployments across environments
- **Automation**: Eliminates manual configuration drift
- **Auditability**: Clear record of infrastructure changes
- **Separation of Concerns**: Terraform handles provisioning, Ansible handles configuration

### 2. Modular Terraform Design

**Decision**: Organize Terraform into reusable modules with clear inputs/outputs

**Rationale**:
- **Reusability**: Modules used across dev/prod without duplication
- **Maintainability**: Changes to a module propagate consistently
- **Scalability**: Adding new resources doesn't require rewriting core modules
- **Team Collaboration**: Different teams modify different modules independently
- **Testing**: Modules can be unit tested in isolation
- **Documentation**: Module interfaces clearly document expectations

### 3. Multiple VPC Architecture

**Decision**: Isolate infrastructure into separate VPCs with controlled peering

**Rationale**:
- **Blast Radius**: Issues in one environment don't cascade to others
- **Security Boundaries**: Network segmentation implements defense-in-depth
- **Compliance**: Sensitive workloads isolated from non-critical systems
- **Cost Allocation**: Track infrastructure costs per environment
- **Independent Scaling**: Each environment scales without affecting others
- **Team Autonomy**: Different teams manage different VPCs
- **Multi-AZ Resilience**: VPC peering maintains availability across zones

### 4. Dynamic Inventory

**Decision**: Use AWS EC2 dynamic inventory plugin instead of static hosts.ini

**Rationale**:
- **Automatic Discovery**: New instances automatically join without manual updates
- **Tag-Based Grouping**: Group instances by Terraform-applied tags
- **Reduced Maintenance**: No manual host list synchronization
- **Scalability**: Supports auto-scaling group instances
- **Accuracy**: Reflects actual AWS state, not cached data

### 5. Layered Terraform Deployment (VPC2)

**Decision**: Split VPC provisioning into network, peering, and platform layers with separate state files

**Rationale**:
- **Reduced Blast Radius**: Network changes don't trigger platform redeployment
- **Parallel Development**: Teams can work on different layers simultaneously
- **Clearer Dependencies**: Each layer explicitly references parent state
- **Independent Rollback**: Revert platform without touching network infrastructure
- **Debugging**: Easier to isolate and troubleshoot layer-specific issues

### 6. Least-Privilege Security Groups

**Decision**: Implement granular security groups with minimal required access

**Rationale**:
- **Defense in Depth**: Multiple layers restrict unauthorized access
- **Compliance**: Meets industry security standards (CIS, AWS best practices)
- **Auditability**: Clear documentation of traffic flow
- **Incident Response**: Easier to identify and block attack vectors
- **Principle of Least Privilege**: Follows security fundamentals

### 7. Stateless Configuration with Ansible

**Decision**: Use Ansible for idempotent configuration without relying on state files

**Rationale**:
- **Convergence**: Rerunning playbooks safely ensures configuration compliance
- **Disaster Recovery**: Rerun playbooks to recover misconfigured systems
- **Debugging**: No hidden state; all configuration visible in playbooks/roles
- **Documentation**: Playbooks serve as executable documentation
- **Flexibility**: Apply same roles across different host types

### 8. Honeypot Deployment Strategy

**Decision**: Isolate honeypots in dedicated VPC with static IPs and comprehensive logging

**Rationale**:
- **Threat Research**: Isolated network prevents honeypot compromise from affecting production
- **Static IPs**: Eases external threat attribution and tracking
- **Logging**: Fluent Bit forwards all honeypot activity for analysis
- **Metrics**: DynamoDB/Kinesis capture attack patterns
- **Scalability**: Deploy additional honeypots without infrastructure changes

---

## Best Practices

### 1. Infrastructure as Code Governance

#### **Version Control**
- Maintain all infrastructure code in Git repositories
- Use meaningful commit messages documenting infrastructure changes
- Require code review before deployment changes
- Tag releases for versioning infrastructure changes

#### **State Management**
- Never commit state files (`terraform.tfstate`) to version control
- Use `.gitignore` to exclude state files
- Store state files securely with encryption at rest
- Implement state locking to prevent concurrent modifications
- Backup state files regularly and test recovery procedures
- For production, migrate to remote state (S3 + DynamoDB) with encryption

#### **Variable Management**
- Use terraform.tfvars files for environment-specific values
- Exclude tfvars files from version control (add to .gitignore)
- Use environment variables (TF_VAR_*) for sensitive values in CI/CD
- Document all variables in variable declarations
- Validate variable types to catch errors early

### 2. Modular Design Excellence

#### **Module Design**
- Modules should have single responsibility (do one thing well)
- Expose minimal required outputs; avoid exposing internal resource details
- Use meaningful variable and output names
- Include comprehensive variable validation
- Document all module inputs and outputs

#### **Module Reusability**
- Design modules for multiple use cases within the same organization
- Avoid hardcoding values; parameterize everything
- Support different environment types (dev, staging, prod) through variables
- Implement optional features through count/for_each patterns

#### **Module Testing**
- Test modules independently before integration
- Validate outputs produce expected values
- Test with different variable combinations
- Document module usage examples

### 3. Security Fundamentals

#### **Access Control**
- Implement bastion hosts for SSH access to private subnets
- Use security groups to enforce least-privilege access
- Avoid opening ports to 0.0.0.0/0 except where necessary (HTTP/HTTPS)
- Implement and maintain NACLs for additional network segmentation

#### **Data Protection**
- Enable encryption at rest for databases (RDS, DynamoDB, S3)
- Use TLS/HTTPS for data in transit
- Store credentials in AWS Secrets Manager, never in code
- Rotate credentials regularly
- Implement VPC Flow Logs for network traffic analysis

#### **Compliance and Auditing**
- Enable CloudTrail for API audit logging
- Configure CloudWatch for centralized log aggregation
- Implement tagging strategy for resource tracking
- Regular security assessments and penetration testing
- Document security boundaries and network architecture

### 4. Operational Excellence

#### **Monitoring and Observability**
- Deploy monitoring agents on all instances
- Implement centralized logging with Fluent Bit/CloudWatch
- Configure CloudWatch alarms for critical metrics
- Use Grafana dashboards for infrastructure visibility
- Implement distributed tracing for multi-service applications

#### **Disaster Recovery**
- Test backup and restore procedures regularly
- Implement automated backups for databases
- Document recovery procedures
- Establish RTO (Recovery Time Objective) and RPO (Recovery Point Objective) targets
- Maintain backup copies in separate regions

#### **Change Management**
- Use Terraform plan before apply to review changes
- Implement CI/CD pipelines for infrastructure deployment
- Require peer review for production infrastructure changes
- Maintain infrastructure documentation
- Document runbooks for common operational tasks

### 5. Cost Optimization

#### **Resource Sizing**
- Right-size EC2 instances based on actual workload requirements
- Use appropriate instance types (burstable vs. general-purpose)
- Monitor CPU and memory utilization
- Adjust allocated storage based on actual usage

#### **Automation**
- Implement auto-scaling groups for variable workloads
- Use scheduled scaling for predictable traffic patterns
- Clean up unused resources (EIPs, unused subnets)
- Consider reserved instances for baseline capacity

#### **Resource Tagging**
- Implement comprehensive tagging strategy
- Tag all resources with cost center, environment, owner
- Use tags for cost allocation and billing reports
- Enforce tagging policy through Terraform requirements

### 6. Ansible Configuration Best Practices

#### **Idempotency**
- Design roles to be safely rerunnable without side effects
- Use conditional tasks to check state before modification
- Prefer module-based changes over raw shell commands
- Test roles for idempotent behavior

#### **Error Handling**
- Implement error handlers for expected failures
- Use handlers for service restarts and configuration reloads
- Log important configuration changes
- Notify teams of critical changes

#### **Inventory Organization**
- Group hosts logically by function (bastion, microservices, databases)
- Use group variables for shared configuration
- Leverage dynamic inventory to reduce manual maintenance
- Document inventory structure and grouping rationale

#### **Role Organization**
- Follow standard role directory structure (tasks, handlers, files, templates, defaults)
- Keep roles focused and reusable
- Document role purpose and usage
- Use meaningful variable names in defaults/main.yml
- Include comprehensive README in each role

### 7. Environment Isolation

#### **Separation of Concerns**
- Maintain separate VPCs for development, staging, and production
- Use separate AWS accounts for different environments (if possible)
- Implement environment-specific security policies
- Use dedicated state files per environment

#### **Blast Radius Reduction**
- Changes to development infrastructure don't affect production
- Failed deployments in one environment don't cascade
- Allows aggressive testing and iteration in lower environments
- Implements clear separation of infrastructure concerns

---

## Usage and Maintenance

### Initial Deployment

#### **Prerequisites**
- AWS CLI configured with appropriate credentials
- Terraform 1.0+ installed locally
- Ansible 2.9+ installed for configuration management
- SSH key pair created and stored securely
- VPC CIDR blocks planned and documented

#### **Deployment Sequence**

1. **Network Layer Deployment**
   ```bash
   cd infrastructure/terraform_modular_vpc2/dev/01-network
   terraform init
   terraform plan -out=plan.tfstate
   terraform apply plan.tfstate
   ```

2. **Peering Layer Deployment**
   ```bash
   cd ../02-peering
   terraform init
   terraform plan
   terraform apply
   ```

3. **Platform Layer Deployment**
   ```bash
   cd ../03-platform
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configuration Management**
   ```bash
   cd ../../../ansible
   make deploy
   ```

#### **Environment Variables**

Set required environment variables before deployment:
```bash
export TF_VAR_region="us-east-1"
export TF_VAR_project_name="my-project"
export TF_VAR_environment="dev"
export ANSIBLE_INVENTORY=inventory/dev/aws_ec2.yml
```

### Infrastructure Updates

#### **Modifying Infrastructure**

1. **Edit Terraform Code**: Modify `.tf` files with desired changes
2. **Review Changes**: 
   ```bash
   terraform plan -out=plan.tfstate
   ```
3. **Preview Impact**: Carefully review planned additions, modifications, and deletions
4. **Apply Changes**:
   ```bash
   terraform apply plan.tfstate
   ```
5. **Verify**: Confirm infrastructure matches desired state

#### **Configuration Updates**

1. **Update Ansible Roles**: Modify tasks, handlers, templates as needed
2. **Test Changes**: Run playbooks against test hosts first
3. **Verify Idempotency**: Run playbook twice to confirm safe reruns
4. **Deploy to Production**:
   ```bash
   ansible-playbook -i inventory/dev/aws_ec2.yml playbooks/nat_bastion.yml
   ```

### Operational Maintenance

#### **Regular Tasks**

- **Weekly**: Review CloudWatch logs for errors
- **Monthly**: Review security group rules for over-permissive access
- **Monthly**: Check for unused resources (unattached EIPs, unused subnets)
- **Quarterly**: Conduct security audit of network architecture
- **Quarterly**: Review backup retention and recovery procedures
- **Annually**: Evaluate architecture for optimization opportunities

#### **Monitoring and Alerting**

Configure CloudWatch alarms for:
- High EC2 CPU utilization (>80%)
- Low available storage on instances
- NAT Gateway errors
- Database connection count anomalies
- Security group modifications (CloudTrail)

#### **Backup and Recovery**

- RDS: Automated backups with 7-day retention
- S3: Versioning enabled for critical data
- Configuration: Version control for Terraform and Ansible
- Test recovery procedures monthly

### Troubleshooting Common Issues

#### **Terraform State Corruption**

**Problem**: State file becomes inconsistent with actual AWS resources

**Solution**:
1. Create backup: `cp terraform.tfstate terraform.tfstate.backup`
2. Import actual resources: `terraform import aws_instance.example i-1234567890abcdef0`
3. Reconcile state differences
4. Run `terraform plan` to verify state matches actual resources

#### **Ansible Connectivity Issues**

**Problem**: Ansible cannot connect to hosts

**Solution**:
1. Verify SSH key permissions: `chmod 600 /path/to/key.pem`
2. Test connectivity: `ansible all -i inventory -m ping`
3. Check security group allows SSH (port 22)
4. Verify EC2 instances have public IPs or are behind bastion host
5. Check SSH timeout: Add `ansible_ssh_timeout=30` to inventory

#### **VPC Peering Connection Issues**

**Problem**: Traffic cannot flow across peered VPCs

**Solution**:
1. Verify peering connection is accepted: `aws ec2 describe-vpc-peering-connections`
2. Check route tables have peering routes: `aws ec2 describe-route-tables`
3. Verify security groups allow traffic: Check ingress rules
4. Verify NACLs allow traffic: Check network ACL rules
5. Test with traceroute: `traceroute <target-vpc-ip>`

### Scaling Considerations

#### **Horizontal Scaling**

- Increase instance count via Terraform variable modification
- Utilize Auto Scaling Groups for variable workloads
- Deploy additional subnets in new availability zones
- Expand VPC CIDR blocks if necessary

#### **Vertical Scaling**

- Modify EC2 instance types for compute scaling
- Increase RDS instance class for database scaling
- Adjust storage allocations as data grows
- Monitor performance and right-size accordingly

### Future Improvements

#### **Recommended Enhancements**

1. **Remote State Management**: Migrate Terraform state to S3 with DynamoDB locking
2. **CI/CD Integration**: Implement GitOps pipeline for automated deployments
3. **Infrastructure Testing**: Add Terratest or kitchen-terraform for module testing
4. **Container Orchestration**: Evaluate ECS/EKS for containerized workloads
5. **Secret Management**: Implement AWS Secrets Manager rotation for RDS credentials
6. **Advanced Monitoring**: Deploy Prometheus + Grafana for comprehensive observability
7. **Multi-Region**: Expand to additional AWS regions for disaster recovery
8. **Terraform Modules Registry**: Publish internal modules for org-wide reuse
9. **Policy as Code**: Implement OPA/Sentinel for infrastructure policy enforcement
10. **Compliance Automation**: Automate compliance scanning with AWS Config

---

## File Structure

### Top-Level Organization

```
infrastructure/
├── README.md                      # This file
├── .gitignore                     # Git exclusions (including state files)
├── terraform_modular_vpc1/        # Multi-environment platform
├── terraform_modular_vpc2/        # Development and honeypot infrastructure
├── terraform_prod/                # Production environment
└── ansible/                       # Configuration management
```

### Terraform Modular VPC1

```
terraform_modular_vpc1/
└── terraform/
    ├── environments/              # Environment-specific configurations
    │   ├── dev/
    │   └── prod/
    ├── lambda_packages/           # Packaged Lambda functions
    └── modules/                   # Reusable infrastructure modules
        ├── alb/
        ├── api_gateway/
        ├── firehose/
        ├── grafana/
        ├── kms/
        ├── lambda/
        ├── microservices/
        ├── nat_bastion/
        ├── network/
        ├── rds/
        ├── s3/
        ├── secrets/
        ├── security_groups/
        └── vpc_peering/
```

### Terraform Modular VPC2

```
terraform_modular_vpc2/
├── dev/                           # Development environment layers
│   ├── 01-network/                # VPC and networking
│   ├── 02-peering/                # VPC peering configuration
│   └── 03-platform/               # Application platform (honeypots, EC2)
└── modules/                       # Reusable modules
    ├── dynamodb/
    ├── ec2/
    ├── kinesis_firehose/
    ├── s3/
    ├── security/
    └── vpc/
```

### Terraform Production

```
terraform_prod/
├── main.tf                        # Main resource definitions
├── variables.tf                   # Variable declarations
├── outputs.tf                     # Output values
├── providers.tf                   # AWS provider configuration
├── terraform.tfvars               # Environment-specific values (in .gitignore)
└── modules/                       # Production modules
    ├── bastion/
    ├── haproxy/
    ├── microservices/
    ├── rds/
    ├── security_groups/
    └── vpc/
```

### Ansible

```
ansible/
├── ansible.cfg                    # Ansible configuration
├── Makefile                       # Deployment automation targets
├── inventory/                     # Host inventory
│   └── dev/
│       ├── aws_ec2.yml            # Dynamic AWS EC2 inventory
│       ├── hosts.ini              # Static inventory
│       └── group_vars/            # Group-level variables
├── playbooks/                     # Orchestration playbooks
│   ├── nat_bastion.yml
│   ├── zeek_logging.yml
│   ├── hardening.yml
│   └── honeypots.yml
└── roles/                         # Reusable configuration roles
    ├── common/                    # Base system setup
    ├── cowrie/                    # SSH honeypot
    ├── dionaea/                   # Service honeypot
    ├── fail2ban/                  # Intrusion prevention
    ├── fluentbit/                 # Log forwarding
    ├── fluentbit-honeypots/       # Honeypot-specific logging
    ├── hardening_base/            # OS security hardening
    ├── nat_bastion/               # NAT and bastion configuration
    └── zeek/                      # Network IDS
```

---

## Additional Resources

### AWS Architecture Best Practices
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [VPC Design and Architecture](https://docs.aws.amazon.com/vpc/latest/userguide/)

### Terraform Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/language/index.html)
- [Terraform Module Development](https://www.terraform.io/docs/language/modules/develop/index.html)

### Ansible Documentation
- [Ansible User Guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [AWS Inventory Plugin](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html)

### Security and Compliance
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

**Document Version**: 1.0  
**Last Updated**: January 2026  
**Maintainer**: AWS DevOps Team
