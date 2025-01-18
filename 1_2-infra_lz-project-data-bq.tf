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

resource "google_project" "prj_aead_demo_bq" {
  name            = var.prj_bq_data
  project_id      = var.prj_bq_data
  folder_id       = google_folder.fld_aead_encryption_demos.name
  billing_account = var.gcp_billing_id
  auto_create_network = false  # Your org can also enforce "constraints/compute.skipDefaultNetworkCreation"
}

variable "prj_aead_demo_bq_service_list" {
  description ="The list of apis needed for the Data project"
  type = list(string)
  default = [
    "iam.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    # "managedflink.googleapis.com", # BigQuery Engine for Apache Flink API for BQ Jobs
    # "monitoring.googleapis.com", # Cloud Monitoring API
    # "logging.googleapis.com", # Cloud Logging API
  ]
}

variable "prj_aead_demo_bq_services_needed_for_bq_policy_tags" {
  description ="The list of apis needed for Data Catalog BQ Policy Tags"
  type = list(string)
  default = [
    # "managedflink.googleapis.com", # BigQuery Engine for Apache Flink API
    # "monitoring.googleapis.com",
    # "logging.googleapis.com",
    "datacatalog.googleapis.com",
  ]
}

resource "google_project_service" "prj_aead_demo_bq_services" {
  for_each = toset(concat(
    var.prj_aead_demo_bq_service_list,
    var.prj_aead_demo_bq_services_needed_for_bq_policy_tags,
  ))
  project = google_project.prj_aead_demo_bq.project_id
  service = each.key
}

resource "google_project_iam_binding" "project_bq_admin" {
  project     = google_project.prj_aead_demo_bq.project_id
  for_each = toset([
    "roles/servicemanagement.quotaViewer",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.roleAdmin",
    "roles/datacatalog.categoryAdmin",
    "roles/datacatalog.admin",
    "projects/${google_project.prj_aead_demo_bq.project_id}/roles/${google_project_iam_custom_role.iam_customrole_data_prj_admin.role_id}",
  ])
  role        = each.key
  members     = [
    "user:${var.persona_org_admin}",
  ]
}

resource "google_project_iam_custom_role" "iam_customrole_data_prj_admin" {
  role_id     = "customRoleAEADDataOwner"
  title       = "Custom Role AEAD Data Owner"
  description = "A custom role with all permissions needed to manage the AEAD DemoData project"
  project     = google_project.prj_aead_demo_bq.project_id
  permissions = [
    "serviceusage.services.list",
    "serviceusage.services.enable",
    "bigquery.datasets.get",
    "bigquery.datasets.create",
    "bigquery.tables.list",
    "bigquery.tables.get",
    "bigquery.tables.create",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.list",
    "iam.roles.get",
    "datacatalog.taxonomies.create",
    "datacatalog.taxonomies.get",
    "datacatalog.taxonomies.list",
    "datacatalog.taxonomies.update",
    "datacatalog.taxonomies.delete",
    "datacatalog.taxonomies.setIamPolicy", # To apply IAM policy for datacatalog taxonomy
    "datacatalog.categories.setIamPolicy", # To apply IAM policy for datacatalog policytag
  ]
} 

resource "google_project_iam_binding" "project_bq_jobs_creators" {
  project     = google_project.prj_aead_demo_bq.project_id

  role = "projects/${google_project.prj_aead_demo_bq.project_id}/roles/${google_project_iam_custom_role.iam_customrole_bq_jobs_create.role_id}"

  members = [
    "user:${var.persona_clear_text_data_reader}",
    "user:${var.persona_encrypted_text_data_reader}",
    "user:${var.persona_hashed_text_data_reader}",
  ]
}

  resource "google_project_iam_custom_role" "iam_customrole_bq_jobs_create" {
  role_id     = "iam_customrole_BQ_jobs_creator"
  title       = "Custom Role Jobs Creator - BigQuery Permissions"
  description = "A custom role to run BigQuery jobs"
  project     = google_project.prj_aead_demo_bq.project_id
  permissions = [
     "bigquery.jobs.create",
  ]
}
