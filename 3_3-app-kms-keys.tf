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

resource "google_kms_crypto_key_iam_policy" "iampolicy_bq_aead_demo_key_01" {
   crypto_key_id = google_kms_crypto_key.bq_aead_demo_key_01.id
  policy_data = data.google_iam_policy.tfd_iampolicy_bq_aead_demo_key_01.policy_data
}


data "google_iam_policy" "tfd_iampolicy_bq_aead_demo_key_01" {
  binding {
    role          = "roles/cloudkms.cryptoKeyEncrypter"
    members = [
      "user:${var.persona_data_owner}",
    ]
  }

  binding {
    role          = "projects/${google_project.prj_aead_demo_keys.project_id}/roles/${google_project_iam_custom_role.iam_customrole_prj_aead_demo_kms_kek_encrypt_via_delegation.role_id}"

    members = [
      "user:${var.persona_data_owner}",
    ]    
  }

  binding {
    role          = "projects/${google_project.prj_aead_demo_keys.project_id}/roles/${google_project_iam_custom_role.iam_customrole_prj_aead_demo_kms_kek_decrypt_via_delegation.role_id}"

    members = [
      # "user:${var.persona_data_owner}",
      "user:${var.persona_clear_text_data_reader}",
      "user:${var.persona_encrypted_text_data_reader}",
    ]  
  }
}

resource "google_project_iam_custom_role" "iam_customrole_prj_aead_demo_kms_kek_encrypt_via_delegation" {
  project    = google_project.prj_aead_demo_keys.project_id
  role_id     = "custom_role_kms_kek_encrypt_via_delegation"
  title       = "Custom Role - KMS KEK access to encrypt via delegation"
  description = "A custom role needed to create a wrapped DEK Tink key as documented in https://cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions#keysnew_wrapped_keyset"

  permissions = [
     "cloudkms.cryptoKeyVersions.useToEncryptViaDelegation",
  ]
}

resource "google_project_iam_custom_role" "iam_customrole_prj_aead_demo_kms_kek_decrypt_via_delegation" {
  project    = google_project.prj_aead_demo_keys.project_id 
  role_id     = "custom_role_kms_kek_decrypt_via_delegation"
  title       = "Custom Role - KMS KEK access to decrypt via delegation"
  description = "A custom role needed to decrypt/unrwap a DEK Tink key as documented in https://cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions#keyskeyset_chain"

  permissions = [
     "cloudkms.cryptoKeyVersions.useToDecryptViaDelegation",
  ]
}
