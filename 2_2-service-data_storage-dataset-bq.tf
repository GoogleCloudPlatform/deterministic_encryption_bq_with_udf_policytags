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

resource "google_bigquery_dataset" "dataset_aead_deterministic_encrypt" {
  dataset_id                  = "aead_deterministic_encrypt"
  friendly_name               = "aead_deterministic_encrypt"
  description                 = "A BigQuery Dataset to demo Deterministic encryption. See https://developers.google.com/tink/deterministic-aead https://cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions#deterministic_encrypt"
  location                    = var.region
  project                     = google_project.prj_aead_demo_bq.project_id
  # default_table_expiration_ms = 3600000

  labels = {
    env = "encryption_demos"
  }
}

resource "google_bigquery_dataset_iam_policy" "iampolicy_dataset_aead_deterministic_encrypt" {
  project     = google_project.prj_aead_demo_bq.project_id
  dataset_id  = google_bigquery_dataset.dataset_aead_deterministic_encrypt.dataset_id
  policy_data = data.google_iam_policy.tfd_dataset_aead_deterministic_encrypt.policy_data
}

data "google_iam_policy" "tfd_dataset_aead_deterministic_encrypt" {
  binding {
    role = "roles/bigquery.dataOwner"

    members = [
      "user:${var.persona_data_owner}",
    ]
  }
  # binding {
  #   role        = "roles/datacatalog.categoryAdmin" #"projects/${google_project.prj_aead_demo_bq.project_id}/roles/${google_project_iam_custom_role.iam_customrole_data_prj_admin.role_id}"
  #   members     = [
  #     "user:${var.persona_org_admin}",
  #   ]  
  # }
  binding {
    role        = "roles/datacatalog.admin"
    members     = [
      "user:${var.persona_org_admin}",
    ]  
  }
  binding {
    role = "projects/${google_project.prj_aead_demo_bq.project_id}/roles/${google_project_iam_custom_role.iam_customrole_AEAD_table_data_viewer.role_id}"

    members = [
      "user:${var.persona_clear_text_data_reader}",
      "user:${var.persona_encrypted_text_data_reader}",
      "user:${var.persona_hashed_text_data_reader}",
    ]
  }
}

resource "google_project_iam_custom_role" "iam_customrole_AEAD_table_data_viewer" {
  role_id     = "iam_customrole_AEAD_table_data_viewer"
  title       = "Custom Role AEAD Table data viewer - BigQuery Permissions"
  description = "A custom role to view table data in the dataset: ${google_bigquery_dataset.dataset_aead_deterministic_encrypt.dataset_id}"
  project     = google_project.prj_aead_demo_bq.project_id
  permissions = [
     "bigquery.datasets.get",
     "bigquery.tables.list",
     "bigquery.tables.get",
     "bigquery.tables.getData",
  ]
}
