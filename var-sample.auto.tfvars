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


# # Terraform Variable Precedence:
# #   1. Environment variables
# #   2. terraform.tfvars
# #   3. terraform.tfvars.json
# #   4. Any *.auto.tfvars or *.auto.tfvars.json
# #   5. -var and -var-file options on the command line

# gcp_billing_id     = "xxxxxx-xxxxxx-xxxxxx"  # Your org Billing
# gcp_org_id         = "000000000000"
# region             = "europe-west1"

# fldr_name = "AEAD Encryption demos - 03"
# prj_bq_data = "aead-demo-bq-data-03"
# prj_kms_keys_producer = "aead-demo-keys-03"
# gcs_bucket_name_to_upload_data = "fake_pii_uploads-03"

# datapolicy_taxonomy_display_name = "Taxonomy for Data Classification-03"
# datapolicy_taxonomy_description = "A collection of Policy Tags to classify data across the company"

# persona_org_admin  = "admin@YOUR_DOMAIN_NAME.com"
# persona_data_owner = "oscar-owner@YOUR_DOMAIN_NAME.com"
# persona_clear_text_data_reader = "clare-clear-text@YOUR_DOMAIN_NAME.com"
# persona_encrypted_text_data_reader = "bob-blocked@YOUR_DOMAIN_NAME.com"
# persona_hashed_text_data_reader = "harry-hashed@YOUR_DOMAIN_NAME.com"