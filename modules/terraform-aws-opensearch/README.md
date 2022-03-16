# AWS OpenSearch Terraform Module

Terraform module to provision an OpenSearch cluster with internal database authentication.

## Prerequisites

- A [hosted zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html) to route traffic to your OpenSearch domain

## Features

- Create an AWS OpenSearch cluster with internal database authentication
- All node types with local NVMe for high IO performance are supported
