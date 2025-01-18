/*
  Copyright 2025 Google LLC

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

terraform {
  # backend "gcs" {
  #   bucket = "gcs-bucket-terraform-state"
  #   project = "gcp-demos"
  #   prefix = "bq_aead_column_encrypt"
  # }

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.37.0"
    }
  }

  # required_versions {
  #   terraform = ">= 1.15.0"
  # }
}

# provider "google" {
#   # https://cloud.google.com/docs/terraform/authentication
#   impersonate_service_account = var.sa_terraform_org
# }

