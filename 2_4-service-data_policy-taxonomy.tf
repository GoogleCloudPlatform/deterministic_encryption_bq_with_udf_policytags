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

resource "google_data_catalog_taxonomy" "basic_taxonomy_01" {
  project = google_project.prj_aead_demo_bq.project_id
  region = var.region

  display_name =  var.datapolicy_taxonomy_display_name
  description = var.datapolicy_taxonomy_description

  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

  depends_on = [ 
    google_project_service.prj_aead_demo_bq_services,
    google_project_iam_binding.project_bq_admin,
    google_bigquery_dataset_iam_policy.iampolicy_dataset_aead_deterministic_encrypt,
   ]
}

resource "google_data_catalog_taxonomy_iam_policy" "iampolicy_data_catalog_taxonomy_admin" {
  taxonomy = google_data_catalog_taxonomy.basic_taxonomy_01.name
  policy_data = data.google_iam_policy.tfd_iampolicy_data_catalog_taxonomy_admin.policy_data
}

data "google_iam_policy" "tfd_iampolicy_data_catalog_taxonomy_admin" {
  binding {
    role = "roles/datacatalog.admin"
    members = [
      "user:${var.persona_org_admin}",
    ]
  }
}
