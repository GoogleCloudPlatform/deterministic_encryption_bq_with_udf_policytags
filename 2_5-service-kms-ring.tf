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

resource "google_kms_key_ring" "bq_aead_demo_key_ring_01" {
  name       = "bq-aead-demo-key-ring-01"
  location   = var.region
  project    = google_project.prj_aead_demo_keys.project_id
}

resource "google_kms_crypto_key" "bq_aead_demo_key_01" {
  name            = "bq-aead-demo-key-01"
  key_ring        = google_kms_key_ring.bq_aead_demo_key_ring_01.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level= "SOFTWARE"
  }

  lifecycle {
    prevent_destroy = true
  }
}