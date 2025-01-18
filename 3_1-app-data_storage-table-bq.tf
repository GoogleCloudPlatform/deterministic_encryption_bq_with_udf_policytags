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

resource "google_bigquery_table" "fake_pii_data" {
  project     = google_project.prj_aead_demo_bq.project_id
  dataset_id  = google_bigquery_dataset.dataset_aead_deterministic_encrypt.dataset_id

  table_id    = "fake_pii_data"
  description = "A table containing fake / synthetic PII data to illustrate the encryption examples"
  # deletion_protection=false

  depends_on = [
    google_data_catalog_taxonomy.basic_taxonomy_01
  ]
  
  # Schema extracted with: bq show --format=prettyjson aead-demo-bq-01:aead_deterministic_encrypt.fake_pii_data
  schema      = <<EOF
    [
      {
        "mode": "NULLABLE",
        "name": "customer_id",
        "type": "INT64"
      },
      {
        "mode": "NULLABLE",
        "name": "SSN",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "gender",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "birthdate",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "maiden name",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "last name",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "first name",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "address",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "city",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "state",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "zip",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "phone",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "email",
        "type": "STRING",
        "policyTags":{
          "names": [
            "${google_data_catalog_policy_tag.policytag_email.id}"
          ]
        }
      },
      {
        "mode": "NULLABLE",
        "name": "cc_type",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "CCN",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "cc_cvc",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "cc_expiredate",
        "type": "DATE"
      }
    ]
    EOF
}

resource "google_bigquery_job" "load_data" {
  project     = google_project.prj_aead_demo_bq.project_id
  location    = var.region

  job_id      = "load_fake_pii_data_into_table-13" # Change the name every time the job needs to be run

  load {
    source_uris = [
      "gs://${google_storage_bucket.gcs_fake_pii_uploads.id}/${google_storage_bucket_object.csv_file_with_fake_pii_to_populate_bq_table.output_name}"
    ]

    destination_table {
      project_id = google_bigquery_table.fake_pii_data.project
      dataset_id = google_bigquery_table.fake_pii_data.dataset_id
      table_id   = google_bigquery_table.fake_pii_data.table_id
    }

    skip_leading_rows = 0
    schema_update_options = ["ALLOW_FIELD_RELAXATION", "ALLOW_FIELD_ADDITION"]

    write_disposition = "WRITE_APPEND"
    autodetect = true
  }
}