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

resource "google_bigquery_dataset" "dataset_udf_routines_container" {
  project                     = google_project.prj_aead_demo_bq.project_id
  location                    = var.region

  dataset_id                  = "udf_routines_container"
  friendly_name               = "udf_routines_container"
  description                 = "A BigQuery Dataset to store UDF Routines."

  default_table_expiration_ms = 3600000

  labels = {
    env = "encryption_demos"
  }
}

resource "google_bigquery_dataset_iam_policy" "iampolicy_dataset_udf_routines_container" {
  project     = google_project.prj_aead_demo_bq.project_id
  dataset_id  = google_bigquery_dataset.dataset_udf_routines_container.dataset_id
  policy_data = data.google_iam_policy.tfd_dataset_udf_routines_container.policy_data
}

data "google_iam_policy" "tfd_dataset_udf_routines_container" {
  binding {
    role = "roles/bigquery.dataOwner"

    members = [
      "user:${var.persona_data_owner}",
    ]
  }
  binding {
    role = "projects/${google_project.prj_aead_demo_bq.project_id}/roles/${google_project_iam_custom_role.iam_customrole_AEAD_udf_routine_user.role_id}"

    members = [
      "user:${var.persona_clear_text_data_reader}",
      "user:${var.persona_encrypted_text_data_reader}",
      "user:${var.persona_hashed_text_data_reader}",
    ]
  }
}

resource "google_project_iam_custom_role" "iam_customrole_AEAD_udf_routine_user" {
  role_id     = "iam_customrole_AEAD_udf_routine_user"
  title       = "Custom Role AEAD UDF Routine user - BigQuery Permissions"
  description = "A custom role to run the UDF Routine in the dataset: ${google_bigquery_dataset.dataset_udf_routines_container.dataset_id}"
  project     = google_project.prj_aead_demo_bq.project_id
  permissions = [
     "bigquery.routines.get",
  ]
}
