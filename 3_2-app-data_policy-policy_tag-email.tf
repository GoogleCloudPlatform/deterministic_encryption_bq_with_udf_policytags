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

resource "google_data_catalog_policy_tag" "policytag_email" {
  taxonomy = google_data_catalog_taxonomy.basic_taxonomy_01.id
  display_name = "EMAIL"
  description = "A Policy Tag to identify Email columns in BQ Tables"
}

resource "google_data_catalog_policy_tag_iam_policy" "iampolicy_policytag_email_unrestricted_finegrained_readers" {
  policy_tag = google_data_catalog_policy_tag.policytag_email.name
  policy_data = data.google_iam_policy.tfd_policytag_email_unrestricted_finegrained_readers.policy_data
}

data "google_iam_policy" "tfd_policytag_email_unrestricted_finegrained_readers" {
  binding {
    role = "roles/datacatalog.categoryFineGrainedReader"
    members = [
      "user:${var.persona_org_admin}",
      "user:${var.persona_clear_text_data_reader}",
    ]
  }
}

resource "google_bigquery_datapolicy_data_policy" "dp_SHA256_hash_STRING_or_BYTES" {
  project = google_project.prj_aead_demo_bq.project_id
  location = var.region
  policy_tag       = google_data_catalog_policy_tag.policytag_email.name

  data_policy_id   = "dp_SHA256_hash_STRING_or_BYTES"  
  
  data_policy_type = "DATA_MASKING_POLICY"  
  data_masking_policy {
    predefined_expression = "SHA256" # SHA256, ALWAYS_NULL, DEFAULT_MASKING_VALUE, LAST_FOUR_CHARACTERS, FIRST_FOUR_CHARACTERS, EMAIL_MASK, DATE_YEAR_MASK.
  }
}

resource "google_bigquery_datapolicy_data_policy_iam_policy" "iampolicy_dp_SHA256_hash_STRING_or_BYTES_MaskedReaders" {
  project = google_bigquery_datapolicy_data_policy.dp_SHA256_hash_STRING_or_BYTES.project
  location = google_bigquery_datapolicy_data_policy.dp_SHA256_hash_STRING_or_BYTES.location
  data_policy_id = google_bigquery_datapolicy_data_policy.dp_SHA256_hash_STRING_or_BYTES.data_policy_id
  policy_data = data.google_iam_policy.tfd_dp_SHA256_hash_STRING_or_BYTES_MaskedReaders.policy_data
}

data "google_iam_policy" "tfd_dp_SHA256_hash_STRING_or_BYTES_MaskedReaders" {
  binding {
    role = "roles/bigquerydatapolicy.maskedReader"
    members = [
      "user:${var.persona_hashed_text_data_reader}",
    ]
  }
}

resource "google_bigquery_datapolicy_data_policy" "dp_deterministic_encrypt_STRING" {
  project = google_project.prj_aead_demo_bq.project_id
  location = var.region
  policy_tag       = google_data_catalog_policy_tag.policytag_email.name

  data_policy_id   = "dp_deterministic_encrypt_STRING"
  
  data_policy_type = "DATA_MASKING_POLICY"  
  data_masking_policy {
    routine = google_bigquery_routine.custom_masking_routine_deterministically_encrypt_column.id
  }
}

resource "google_bigquery_datapolicy_data_policy_iam_policy" "iampolicy_dp_deterministic_encrypt_STRING_MaskedReaders" {
  project = google_bigquery_datapolicy_data_policy.dp_deterministic_encrypt_STRING.project
  location = google_bigquery_datapolicy_data_policy.dp_deterministic_encrypt_STRING.location
  data_policy_id = google_bigquery_datapolicy_data_policy.dp_deterministic_encrypt_STRING.data_policy_id
  policy_data = data.google_iam_policy.tdf_dp_deterministic_encrypt_STRING_MaskedReaders.policy_data
}

data "google_iam_policy" "tdf_dp_deterministic_encrypt_STRING_MaskedReaders" {
  binding {
    role = "roles/bigquerydatapolicy.maskedReader"
    members = [
      "user:${var.persona_encrypted_text_data_reader}",
    ]
  }
}
