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

resource "google_bigquery_routine" "custom_masking_routine_deterministically_encrypt_column" {
  project              = google_project.prj_aead_demo_bq.project_id
  dataset_id           = google_bigquery_dataset.dataset_udf_routines_container.dataset_id

  routine_id           = "custom_masking_routine_deterministically_encrypt_column"
  routine_type         = "SCALAR_FUNCTION"
  language             = "SQL"
  data_governance_type = "DATA_MASKING"

  arguments {
    name = "col_to_encrypt"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  } 

  return_type          = "{\"typeKind\" :  \"STRING\"}"
  definition_body          = <<-EOS
    -- When using this User-Defined Funciont (UDF) as a "Data Policy custom masking routine" as documented in https://cloud.google.com/bigquery/docs/user-defined-functions#custom-mask
    -- The users with maskedReader permission in the Data Policy, DO NOT NEED ACCESS TO READ THIS UDF BODY, But they need to be included in the role below:
    --   > Access to decrypt/unwrap the DEK using the KMS KEK (at KMS Key level):
    --     "projects/${google_project.prj_aead_demo_keys.project_id}/roles/${google_project_iam_custom_role.iam_customrole_prj_aead_demo_kms_kek_decrypt_via_delegation.role_id}"
    
    -- When using this UDF directly in a GoogleSQL query as documented in https://cloud.google.com/bigquery/docs/user-defined-functions
    -- The users need to be included in these roles:
    --   > Access to decrypt/unwrap the DEK using the KMS KEK (at KMS Key level):
    --       "projects/${google_project.prj_aead_demo_keys.project_id}/roles/${google_project_iam_custom_role.iam_customrole_prj_aead_demo_kms_kek_decrypt_via_delegation.role_id}"
    --   > Access get the UDF (at dataset level):
    --       "projects/${google_project.prj_aead_demo_bq.project_id}/roles/${google_project_iam_custom_role.iam_customrole_AEAD_udf_routine_user.role_id}" and 
    --   > Access to read the Table data (at dataset level)
    --       "projects/${google_project.prj_aead_demo_bq.project_id}/roles/${google_project_iam_custom_role.iam_customrole_AEAD_table_data_viewer.role_id}"

      TO_BASE64( -- RETURNS STRING: Input and output argument type must be the same for function with DATA_MASKING data governance type
        DETERMINISTIC_ENCRYPT( -- RETURNS BYTES: Needs to be converted to STRING
          KEYS.KEYSET_CHAIN(
            "gcp-kms://${google_kms_crypto_key.bq_aead_demo_key_01.id}",

            ${replace(var.instructions_to_obtain_the_wrapped_dek_keyset_bytes, "KMS_KEY_PATH", "gcp-kms://${google_kms_crypto_key.bq_aead_demo_key_01.id}")}
            ${file("${path.module}/wrapped_dek_keyset_bytes.txt")}

          ),
          col_to_encrypt,

          -- The parameter "additional_data" can not be used: At most 1 argument is allowed for function with DATA_MASKING data governance type
          "" --col_additional_data
        )
      )
 
    ${replace(var.instructions_to_run_the_udfs, "PROJECT_ID", "${google_project.prj_aead_demo_bq.project_id}")}
  EOS
}
