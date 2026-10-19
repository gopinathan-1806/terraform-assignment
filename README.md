# Notes

## Task 1 - EC2 instances

All 5 instances come from one map variable (`instances`). Each entry has its own instance type, root volume type, size and key pair. `db-1` uses io2.

**Protected instance: `db-1`.** It is the database box with the io2 disk, so it is the only one I can't afford to lose by accident. The others can be rebuilt from code. Its `prevent_destroy = true` makes Terraform stop with an error if a plan would delete or replace it.

`prevent_destroy` can't be set from a variable, so I split the map into two resource blocks (protected and normal). The outputs merge them back into one map.

`prevent_destroy` only guards against Terraform. It won't stop someone deleting the instance from the console.

## Task 2 - Remote state

The S3 backend with DynamoDB locking is in `task1-2-ec2-fleet/versions.tf`. The `backend-bootstrap` folder creates the bucket and lock table. Run it once first, because the backend can't create itself.

**With local state:** the state file sits on each person's laptop. If two people run apply at the same time, each works from their own copy. They can create duplicate resources or overwrite each other's changes, and afterwards the state files no longer match what is really in AWS.

**With S3 + DynamoDB:** everyone uses the same state file in S3. Before an apply, Terraform writes a lock entry in DynamoDB. The second person gets "Error acquiring the state lock" and has to wait until the first run is done.

## Task 3 - IAM

- `group1` (engine, ci) has no console password, so these users can only use the CLI or API.
- `group2` (alice, bob) has console and CLI access.
- `roleA` allows everything and then explicitly denies `iam:*`, so IAM is blocked.
- `roleB` can only assume roleC in Account B.
- `roleC` has full access to one S3 bucket. Only `role/roleB` from Account A can assume it.

**1. Would I use IAM users with access keys for engine and ci in production?**
No. Access keys never expire, and they tend to leak through git, CI variables and laptops. For `ci` I would use OIDC, so the pipeline gets temporary credentials and no secret is stored. For `engine` I would use a role attached to wherever it runs (EC2, ECS, EKS or Lambda). I only made IAM users here because the assignment asked for them.

**2. Why trust roleB's ARN and not the whole Account A?**
Trusting the account root means any user or role in Account A could assume roleC, as long as Account A gave them permission. Account B would have no say in who gets in. Trusting `role/roleB` means Account B itself only lets that one role in, whatever Account A's policies say.

## Task 4 - ci policy

The policy is in `task3-5-iam/account-a/policies/ci-policy.json.tpl`. It allows:
- pushing images to one ECR repo
- registering a task definition and updating one ECS service
- reading one S3 bucket (`GetObject` and `ListBucket`)

I also added `iam:PassRole`, limited to the ECS task roles, because registering a task definition fails without it.

**Left out on purpose:**
- Pulling images, and creating or deleting repos or images. CI only pushes.
- Creating or deleting ECS services and clusters, running tasks. CI only deploys a new revision.
- Writing to S3. The task said read only.
- `iam:PassRole` on `*`. That is an easy way to escalate privileges, so it is limited to two roles.
- KMS, logs and other services. Nothing here needs them. If the bucket or repo uses a custom KMS key, `kms:Decrypt` will need adding.
- Managed policies like PowerUser, which are far too wide.

`ecr:GetAuthorizationToken`, `ecs:RegisterTaskDefinition` and `ecs:DescribeTaskDefinition` use `Resource: "*"` because AWS doesn't support narrowing them.

## Task 5 - The bug

The fixed code is in `task5-bugfix/fixed.tf`.

**Trust policy:** it said `user/roleB`, but roleB is a role, so it should be `role/roleB`. There is no user called roleB, so IAM rejects the policy as an invalid principal. Even if it were accepted, roleB's identity is `role/roleB`, so STS would deny it.

**Permissions policy:** `s3:*` on `Resource = "*"` gives access to every bucket in Account B, not just the one it should be limited to. I changed it to the bucket ARN plus `bucket/*`. Both are needed: bucket actions like `ListBucket` use the bucket ARN, and object actions like `GetObject` use `bucket/*`.
