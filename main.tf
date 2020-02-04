# Copyright (c) 2020 Palo Alto Networks
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the documentation
#      and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

provider "aws" {
  region = var.region
}

# Generate a random ExternalID for Prisma Cloud
resource "random_string" "external_id" {
  length  = 32
  special = false
}

# Create the IAM role for Prisma Cloud
resource "aws_iam_role" "prismacloud_role" {
  name               = var.role_name
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::188619942792:root"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringEquals": {
            "sts:ExternalId": "${random_string.external_id.result}"
          }
        }
      }
    ]
  }
  EOF
}

# Attach the SecurityAudit managed policy ARN
resource "aws_iam_role_policy_attachment" "prismacloud_role_policy_attachment" {
  role       = aws_iam_role.prismacloud_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# Create and attach the ReadOnly inline policy
resource "aws_iam_role_policy" "prismacloud_iam_readonly_policy" {
  name   = "PrismaCloud-IAM-ReadOnly-Policy"
  role   = aws_iam_role.prismacloud_role.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "apigateway:GET",
          "cognito-identity:ListTagsForResource",
          "cognito-idp:ListTagsForResource",
          "ecr:DescribeImages",
          "ecr:GetLifecyclePolicy",
          "elasticbeanstalk:ListTagsForResource",
          "elasticfilesystem:DescribeTags",
          "glacier:GetVaultLock",
          "glacier:ListTagsForVault",
          "logs:GetLogEvents",
          "mq:listBrokers",
          "mq:describeBroker",
          "ram:GetResourceShares",
          "secretsmanager:DescribeSecret",
          "ssm:GetParameters",
          "ssm:ListTagsForResource",
          "sqs:SendMessage",
          "elasticmapreduce:ListSecurityConfigurations",
          "sns:listSubscriptions"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

# Create and attach the Remediation inline policy
resource "aws_iam_role_policy" "prismacloud_iam_remediation_policy" {
  name   = "PrismaCloud-IAM-Remediation-Policy"
  role   = aws_iam_role.prismacloud_role.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "iam:UpdateAccountPasswordPolicy",
          "ec2:ModifyImageAttribute",
          "rds:ModifyDBSnapshotAttribute",
          "s3:PutBucketAcl",
          "ec2:RevokeSecurityGroupIngress"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}
