# Hotel Booking DevOps Assessment

This repository contains a production-oriented DevOps assessment solution for Terraform infrastructure design and database reliability.

The solution is built for the assessment requirement to provide Terraform infrastructure design, Docker Compose database setup, database migration and seed data, backup and restore scripts, and a clear README with setup and verification steps.

Actual AWS deployment is not required. Terraform is designed to be validated through formatting, initialization, validation, and plan review.

---

## Assessment Scope

This repository implements the following assessment requirements:

- Terraform code for AWS infrastructure design
- Internet to Application Load Balancer to ECS Fargate to private RDS PostgreSQL
- VPC with public and private subnets
- ALB, ECS, and RDS security groups
- ECS cluster, task definition, and service
- Private RDS PostgreSQL accessible only from ECS
- Dev and prod Terraform environments
- Docker Compose setup for local PostgreSQL
- SQL migration files
- Seed data for at least 100 hotel bookings
- Multiple cities, organizations, statuses, and booking events
- Query optimization using database indexes
- Backup and restore shell scripts
- GitHub Actions workflow for Terraform validation

---

## Architecture

```text
Internet
  |
  v
Application Load Balancer
  |
  v
ECS Fargate Service
  |
  v
Private RDS PostgreSQL
```

### AWS Design Summary

```text
VPC
├── Public Subnet A
├── Public Subnet B
├── Private Subnet A
├── Private Subnet B
├── Internet Gateway
├── Public Route Table
├── Private Route Table
├── Application Load Balancer
├── ECS Fargate Cluster
├── ECS Task Definition
├── ECS Service
└── Private RDS PostgreSQL
```

---

## Repository Structure

```text
assesment-1/
├── .gitignore
├── README.md
├── output.txt
├── docker/
│   ├── docker-compose.yml
│   └── db/
│       ├── .env
│       ├── .env.example
│       ├── migrations/
│       │   ├── 001_create_schema.sql
│       │   └── 002_create_indexes.sql
│       └── seed/
│           └── 001_seed_hotel_bookings.sql
├── infra/
│   ├── modules/
│   │   ├── network/
│   │   ├── ecs/
│   │   └── rds/
│   └── envs/
│       ├── dev/
│       └── prod/
├── scripts/
│   ├── backup.sh
│   └── restore.sh
├── backups/
|── .github/
│     └── workflows/
│         └── terraform-Dev-validation.yml
│         └── terraform-Manual-Trigger.yml
│         └── terraform-Prod-validation.yml
|
└── .gitignore
```

---

## Prerequisites

Install the following tools:

```text
Terraform
Docker
Docker Compose
AWS CLI
Git
```

AWS deployment is not mandatory for this assessment. The Terraform code can be reviewed using plan-only commands.

---

## Part 1: Terraform Infrastructure Design

Terraform creates the following infrastructure:

```text
Internet → Application Load Balancer → ECS Fargate → Private RDS PostgreSQL
```

### Main Components

| Component           | Purpose                                                               |
| ------------------- | --------------------------------------------------------------------- |
| VPC                 | Isolated AWS network                                                  |
| Public Subnets      | Host the internet-facing Application Load Balancer                    |
| Private Subnets     | Host ECS tasks and RDS database                                       |
| Internet Gateway    | Allows internet traffic to reach the ALB                              |
| ALB Security Group  | Allows HTTP traffic from internet                                     |
| ECS Security Group  | Allows traffic only from ALB                                          |
| RDS Security Group  | Allows PostgreSQL traffic only from ECS                               |
| ECS Cluster         | Runs Fargate services                                                 |
| ECS Task Definition | Defines container image, CPU, memory, port, and environment variables |
| ECS Service         | Runs and maintains application tasks                                  |
| RDS PostgreSQL      | Private managed PostgreSQL database                                   |

---

## Why RDS Is Private

RDS is deployed only in private subnets.

```hcl
publicly_accessible = false
```

The RDS security group allows PostgreSQL traffic only from the ECS service security group.

```text
ECS Security Group → RDS Security Group → Port 5432
```

This means the database is not reachable from the public internet.

---

## Why Two Public And Two Private Subnets

Two public and two private subnets are used for high availability.

Each AWS subnet belongs to one Availability Zone. By using two Availability Zones, the design avoids dependency on a single Availability Zone.

```text
Public Subnet A   ap-south-1a
Public Subnet B   ap-south-1b
Private Subnet A  ap-south-1a
Private Subnet B  ap-south-1b
```

### Public Subnets

The Application Load Balancer is placed across public subnets.

This is required because an Application Load Balancer should be deployed across multiple Availability Zones for high availability.

### Private Subnets

ECS tasks and RDS are placed in private subnets.

This keeps application compute and database resources protected from direct public access.

---

## Part 2: Terraform Environment Handling

The repository contains two Terraform environments:

```text
infra/envs/dev
infra/envs/prod
```

Each environment has separate configuration for:

```text
variables
tfvars
resource sizing
RDS backup retention
deletion protection setting
```

---

## Dev Environment

Dev is configured for lower cost and testing.

```text
RDS instance class: db.t4g.micro
RDS Multi-AZ: disabled
RDS backup retention: 1 day
RDS deletion protection: disabled
Final snapshot: skipped
ECS desired tasks: 1
Task CPU: 256
Task memory: 512 MB
NAT Gateway: disabled
```

Run Terraform commands for dev:

```bash
cd infra/envs/dev
terraform init
terraform fmt -recursive ../../
terraform validate
terraform plan -refresh=false
```

---

## Prod Environment

Prod is configured with stronger reliability and protection.

```text
RDS instance class: db.t4g.small
RDS Multi-AZ: enabled
RDS backup retention: 7 days
RDS deletion protection: enabled
Final snapshot: enabled
ECS desired tasks: 2
Task CPU: 512
Task memory: 1024 MB
NAT Gateway: enabled
```

Run Terraform commands for prod:

```bash
cd infra/envs/prod
terraform init
terraform fmt -recursive ../../
terraform validate
terraform plan -refresh=false
```

---

## Backend State Configuration Note

For this assessment, local Terraform state is acceptable for plan-only review.

In a real production setup, Terraform state should be stored remotely using an S3 backend with DynamoDB locking.

Recommended production backend example:

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state-bucket"
    key            = "hotel-booking/prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

For assessment review, backend can be disabled during CI validation:

```bash
terraform init -backend=false
```

---

## Part 3: GitHub Actions Terraform Validation

Two separate GitHub Actions workflows are available — one for each environment.

### Dev Workflow

```text
.github/workflows/terraform-dev-validation.yml
```

Triggers on PRs changing `infra/envs/dev/**`.

### Prod Workflow

```text
.github/workflows/terraform-prod-validation.yml
```

Triggers on PRs changing `infra/envs/prod/**`.

### What Each Workflow Does

1. **Terraform Format** — `terraform fmt -recursive ../../`
2. **Terraform Init** — `terraform init -backend=false -upgrade`
3. **Terraform Validate** — `terraform validate`
4. **Terraform Plan** — `terraform plan -refresh=false -no-color`
5. **Summary** — Results printed to PR via `GITHUB_STEP_SUMMARY`

### How to Configure

#### 1. Push to GitHub

```bash
git remote add origin https://github.com/YOUR-ORG/hotel-booking-devops.git
git push -u origin main
```

#### 2. Add AWS Secrets

| Secret Name | Value |
|------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |

---

## Part 4: Local Database Setup

The local database uses PostgreSQL with Docker Compose.

### Step 1: Create Environment File

```bash
cp docker/db/.env.example docker/db/.env
```

### Step 2: Start PostgreSQL

```bash
cd docker
docker compose up -d
```

### Step 3: Verify Container Is Running

```bash
docker ps
```

Expected container:

```text
hotel-booking-postgres
```

### Step 4: Connect To Database

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking
```

### Step 5: Verify Tables

Inside PostgreSQL shell:

```sql
\dt
```

Expected tables:

```text
hotel_bookings
booking_events
```

---

## Database Schema

### hotel_bookings

Stores hotel booking records.

Important columns:

```text
booking_id
booking_reference
organization_id
hotel_id
city
check_in_date
check_out_date
total_amount
booking_status
created_at
updated_at
```

### booking_events

Stores booking lifecycle events.

Important columns:

```text
booking_event_id
booking_id
event_type
event_payload
created_at
```

Example event types:

```text
booking_created
payment_authorized
booking_confirmed
guest_checked_in
guest_checked_out
booking_cancelled
```

---

## Part 5: Seed Data

The seed script is located at:

```text
docker/db/seed/001_dev_seed_hotel_bookings.sql
```

It creates:

```text
125 hotel bookings
Multiple cities
Multiple organizations
Multiple booking statuses
Booking events for created bookings
```

Verify hotel booking seed data:

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "SELECT COUNT(*) FROM hotel_bookings;"
```

Expected result:

```text
125
```

Verify booking events:

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "SELECT COUNT(*) FROM booking_events;"
```

Expected result:

```text
125
```

---

## Seed Data Policy

Seed booking data is for local and dev validation only.

Production should not receive fake customer booking data.

### Local And Dev Can Have

```text
Fake hotel bookings
Fake guest names
Fake emails
Fake booking events
Demo cities
Demo booking statuses
```

### Production Should Have Only

```text
Schema migrations
Indexes
Required reference data
Required configuration data
```

### Production Should Not Have

```text
Fake guests
Fake customer emails
Fake hotel bookings
Fake booking events
```

This is important because production should contain only real business data.

---

## Part 5: Query Optimization

The assessment query is:

```sql
SELECT organization_id, booking_status, COUNT(*), SUM(total_amount)
FROM hotel_bookings
WHERE city = 'Delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY organization_id, booking_status;
```

This query filters by:

```text
city
created_at
```

Then groups by:

```text
organization_id
booking_status
```

---

## Indexing Decision

The recommended index for this query is:

```sql
CREATE INDEX IF NOT EXISTS hotel_bookings_city_created_at_organization_status_index
    ON hotel_bookings(city, created_at DESC, organization_id, booking_status);
```

### Why This Index Is Useful

The query first filters records where:

```sql
city = 'Delhi'
```

So `city` is placed first in the index.

The query also filters recent records:

```sql
created_at >= NOW() - INTERVAL '30 days'
```

So `created_at` is placed after `city`.

The query groups the filtered data by:

```sql
organization_id, booking_status
```

So these columns are included in the same index to help PostgreSQL process the filtered and grouped rows more efficiently.

### Important Note About Small Local Data

The local database has only 125 seed records. PostgreSQL may still choose a sequential scan because scanning a small table can be cheaper than using an index.

This is normal.

In production, where the table contains thousands or millions of rows, the index becomes much more useful.

---

## How To Verify Index Usage

Run this command:

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "
EXPLAIN ANALYZE
SELECT organization_id, booking_status, COUNT(*), SUM(total_amount)
FROM hotel_bookings
WHERE city = 'Delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY organization_id, booking_status;
"
```

If PostgreSQL uses the index, the output may show:

```text
Index Scan
Bitmap Index Scan
```

If the table is small, PostgreSQL may show:

```text
Seq Scan
```

That is acceptable for local testing because the optimizer chooses the cheapest plan.

---

## Additional Indexes

The project also includes indexes for common production access patterns:

```sql
CREATE INDEX IF NOT EXISTS hotel_bookings_city_index
    ON hotel_bookings(city);

CREATE INDEX IF NOT EXISTS hotel_bookings_created_at_desc_index
    ON hotel_bookings(created_at DESC);

CREATE INDEX IF NOT EXISTS hotel_bookings_organization_id_index
    ON hotel_bookings(organization_id);

CREATE INDEX IF NOT EXISTS hotel_bookings_booking_status_index
    ON hotel_bookings(booking_status);

CREATE INDEX IF NOT EXISTS hotel_bookings_organization_status_created_at_index
    ON hotel_bookings(organization_id, booking_status, created_at DESC);

CREATE INDEX IF NOT EXISTS booking_events_booking_id_created_at_index
    ON booking_events(booking_id, created_at DESC);
```

### Explanation

| Index                                       | Reason                                                                           |
| ------------------------------------------- | -------------------------------------------------------------------------------- |
| city                                        | Speeds up city-based hotel search                                                |
| created_at                                  | Speeds up latest booking reports                                                 |
| organization_id                             | Helps tenant-wise filtering                                                      |
| booking_status                              | Helps dashboards filtering pending, confirmed, completed, and cancelled bookings |
| organization_id, booking_status, created_at | Helps organization-wise latest booking queries by status                         |
| booking_id, created_at                      | Helps fetch booking event history quickly                                        |

---

## Part 6: Backup And Restore

The scripts are located in:

```text
scripts/backup.sh
scripts/restore.sh
```

These scripts are for the local Docker PostgreSQL database.

---

## Backup Local Database

Make the script executable:

```bash
chmod +x scripts/backup.sh
```

Run backup:

```bash
./scripts/backup.sh
```

The script creates a timestamped dump file under:

```text
backups/
```

Example backup file:

```text
backups/hotelbooking_20260706_113000.dump
```

The backup uses:

```text
pg_dump
```

---

## Restore Local Database

Make the script executable:

```bash
chmod +x scripts/restore.sh
```

Run restore:

```bash
./scripts/restore.sh backups/hotelbooking_20260706_113000.dump
```

The restore script performs these steps:

```text
Copies backup file into PostgreSQL container
Terminates active database connections
Drops the existing local database
Creates a fresh database
Restores the dump using pg_restore
Removes temporary restore file from the container
```

---

## How To Verify Restore Worked Successfully

After running restore, verify the following.

### 1. Check Container Is Running

```bash
docker ps
```

Expected container:

```text
hotel-booking-postgres
```

### 2. Check Tables Exist

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "\dt"
```

Expected tables:

```text
hotel_bookings
booking_events
```

### 3. Check Record Count

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "SELECT COUNT(*) FROM hotel_bookings;"
```

Expected result:

```text
125
```

Check booking events:

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "SELECT COUNT(*) FROM booking_events;"
```

Expected result:

```text
125
```

### 4. Check Sample Records

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "
SELECT booking_reference, organization_id, city, booking_status, created_at
FROM hotel_bookings
ORDER BY created_at DESC
LIMIT 10;
"
```

If records are returned, restored data is readable.

### 5. Check Indexes Exist

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "\di"
```

Expected indexes include:

```text
hotel_bookings_city_index
hotel_bookings_created_at_desc_index
hotel_bookings_organization_id_index
hotel_bookings_booking_status_index
hotel_bookings_organization_status_created_at_index
hotel_bookings_city_created_at_organization_status_index
booking_events_booking_id_created_at_index
```

### 6. Strong Restore Test

This is the best practical proof.

First, check current record count:

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "SELECT COUNT(*) FROM hotel_bookings;"
```

Expected:

```text
125
```

Take a backup:

```bash
./scripts/backup.sh
```

Delete some test data:

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "DELETE FROM hotel_bookings WHERE city = 'Delhi';"
```

Check count again:

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "SELECT COUNT(*) FROM hotel_bookings;"
```

The count should be less than 125.

Restore the backup:

```bash
./scripts/restore.sh backups/hotelbooking_YYYYMMDD_HHMMSS.dump
```

Check count again:

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "SELECT COUNT(*) FROM hotel_bookings;"
```

Expected:

```text
125
```

If the original count returns, restore worked successfully.

---

## RDS Backup And Restore Strategy

The local `backup.sh` and `restore.sh` scripts are for Docker PostgreSQL.

For AWS RDS, production backup is handled using:

```text
Automated backups
Manual snapshots
Point-in-time recovery
```

RDS backup retention is configured through Terraform.

### Dev RDS

```text
Backup retention: 1 day
Deletion protection: disabled
Final snapshot: skipped
```

### Prod RDS

```text
Backup retention: 7 days
Deletion protection: enabled
Final snapshot: enabled
```

RDS restore normally creates a new RDS instance from a snapshot or point-in-time backup.

It does not directly overwrite the existing production database.

Recommended RDS restore flow:

```text
Restore snapshot or point-in-time backup
Create new RDS instance
Verify schema and data
Point application to restored endpoint if required
```

---

## Docker Image Note

This assessment uses a placeholder ECS image:

```text
nginx:1.27-alpine
```

This is acceptable because the assessment focuses on infrastructure design and database reliability.

If a real application is added later, build and push the application image to Docker Hub or AWS ECR.

Example:

```hcl
container_image = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/hotel-booking-api:v1.0.0"
```

---

## Commands Used By Reviewer

Terraform review commands:

```bash
terraform fmt
terraform init
terraform validate
terraform plan -refresh=false
```

Database review commands:

```bash
docker compose up
./scripts/backup.sh
./scripts/restore.sh
```

---

## Full Local Verification Flow

Run the following commands from repository root.

```bash
cp docker/db/.env.example docker/db/.env
```

```bash
cd docker
docker compose up -d
cd ..
```

```bash
docker ps
```

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "\dt"
```

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "SELECT COUNT(*) FROM hotel_bookings;"
```

```bash
chmod +x scripts/backup.sh scripts/restore.sh
```

```bash
./scripts/backup.sh
```

```bash
./scripts/restore.sh backups/hotelbooking_YYYYMMDD_HHMMSS.dump
```

```bash
docker exec -i hotel-booking-postgres psql -U hoteladmin -d hotelbooking -c "SELECT COUNT(*) FROM hotel_bookings;"
```

---

## Production Improvement Ideas

For real production, recommended improvements are:

```text
Use HTTPS listener on ALB with ACM certificate
Use AWS ECR for private container images
Use AWS Secrets Manager for application secrets
Use ECS autoscaling
Use CloudWatch alarms
Use WAF in front of ALB
Use Terraform remote backend with S3 and DynamoDB locking
Run database migrations through CI/CD or one-time ECS task
Use NAT Gateway per Availability Zone
Use RDS enhanced monitoring
Use RDS parameter groups
Use read replica if read-heavy
Add application-level health endpoint
```

---

## Final Notes

This repository is designed for assessment review.

Terraform demonstrates production-oriented AWS architecture.

Docker Compose demonstrates local database reliability tasks.

Migration and seed scripts demonstrate schema creation, test data generation, and indexing.

Backup and restore scripts demonstrate practical database recovery skills.

The README provides setup, validation, indexing explanation, and restore verification steps.
