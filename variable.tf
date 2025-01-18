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

variable "gcp_billing_id" {
  type = string
  default = ""
  description = "(Required) The Google Cloud Platform billing account"
}

variable "gcp_org_id" {
  type = string
  default = ""
  description = "(Required) The Google Cloud Platform Organization ID"
}

variable "region" {
  type = string
  default = ""
  description = "(Required) The Google Cloud Region where the demo is implemented."
}

variable "fldr_name" { 
  type = string
  default = ""
  description = "(Required) The name of the folder holding all related projects."
}

variable "prj_bq_data" { 
  type = string
  default = ""
  description = "(Required) The name of the project holding data in BigQuery data (also called 'KMS Key Consumer Project')."
}

variable "prj_kms_keys_producer" { 
  type = string
  default = ""
  description = "(Required) The name of the project holding the encryption keys used in BigQuery (also called 'KMS Key Producer Project')."
}

variable "gcs_bucket_name_to_upload_data" {
  type = string
  default = ""
  description = "(Required) The name of the GCS bucket where data is uploaded to then be transferred to the BigQuery Table."
}

variable "datapolicy_taxonomy_display_name" {
  type = string
  default = "Taxonomy for Data Classification - 01"
}

variable "datapolicy_taxonomy_description" {
  type = string
  default = "A collection of Policy Tags to classify data across the company"
}

variable "persona_data_owner" {
  type = string
  default = ""
  description = "(Required) The User who owns the data and therefore has more permissions like encrypt, decrypte, fine graine reader, etc."
}

variable "persona_org_admin" {
  type = string
  default = ""
  description = "(Required) The Human User Account used by terraform to deploy infrastructure."
}

variable "persona_encrypted_text_data_reader" {
  type = string
  default = ""
  description = "(Required) The Human User Account that can only see encrypted data."
}

variable "persona_hashed_text_data_reader" {
  type = string
  default = ""
  description = "(Required) The Human User Account that can only see hashed data."
}

variable "persona_clear_text_data_reader" {
  type = string
  default = ""
  description = "(Required) The Human User Account that can see data in clear text."
}

# variable sa_terraform_org {
#   type = string
#   default = ""
#   description = "The Service Account used by terraform to deploy infrastructure."
# }

variable "wrapped_dek_keyset_bytes" {
  type = string
  description =  <<-EOS
    (Required) The KMS-wrapped DEK Tink key used to encrypt data in BQ.
    A DEK TinkKey created as per https://cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions#keysnew_wrapped_keyset

    THIS IS A SECRET!!!! : Althoug this DEK key is encrypted, several users in this architecture (including persona_encrypted_text_data_reader)
                           need access to "cloudkms.cryptoKeyVersions.useToDecryptViaDelegation" on the KEK that encrypts this DEK Tink Key.
                           Since users have that permission, they can use DETERMINISTIC_DECRYPT_STRING function to decrypt all data in the table.
                           KEEPING THIS DEK A SECRET is the only way to prevent them from read data in clear text.
    
    INSTRUCTIONS:
      1 - After creating all resources, run this query in the BQ UI to obtain a wrapped key using the KMS KEK:
          SELECT
            FORMAT('%T', FROM_BASE64(TO_BASE64(
              KEYS.NEW_WRAPPED_KEYSET(
                'gcp-kms://projects/PROJECT_ID/locations/GCP_REGION/keyRings/KMS_KEY_RING_ID/cryptoKeys/KMS_KEY_ID',
                'DETERMINISTIC_AEAD_AES_SIV_CMAC_256'
              )
            ))) as wrapped_dek_keyset_bytes;

      2 - Paste the result string in the "default" value below:
  EOS

  default =  <<-EOS
    b'\x0a$\x00wT)...____REPLACE_THIS_ENTIRE_LINE_WITH_THE_WRAPPED_KEY_GENERATED_IN_THE_BIGQUERY_UI____...\x88\xfbmE\x9e\xf9p'
  EOS
}