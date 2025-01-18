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

resource "google_storage_bucket" "gcs_fake_pii_uploads" {
  name          = var.gcs_bucket_name_to_upload_data
  location      = var.region
  project       = google_project.prj_aead_demo_bq.project_id
  force_destroy = true
  uniform_bucket_level_access = true
}


# resource "google_storage_bucket_iam_binding" "gcs_fake_pii_uploads_iam_binding" {
#   bucket = google_storage_bucket.gcs_fake_pii_uploads.name
#   role = google_project_iam_custom_role.prj_aead_demo_bq_data_owner_custom_role.role_id
#   members = [
#     "user:${var.persona_org_admin}",
#   ]
# }

# data "google_iam_policy" "data_owner" {
#   binding {
#     role = "roles/storage.reader"
#     members = [
#       "user:${var.persona_data_owner}",
#     ]
#   }
# }
#
# resource "google_storage_bucket_iam_policy" "policy" {
#   bucket = google_storage_bucket.gcs_fake_pii_uploads.name
#   policy_data = data.google_iam_policy.data_owner.policy_data
# }

resource "google_storage_bucket_object" "csv_file_with_fake_pii_to_populate_bq_table" {
  name         = "sample_fake_pii_data.csv"
  content_type = "csv"
  source       = "./sample_fake_pii_data.csv"
  bucket       = google_storage_bucket.gcs_fake_pii_uploads.id
}
