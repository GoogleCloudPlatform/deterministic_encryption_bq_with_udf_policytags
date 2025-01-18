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

resource "google_project" "prj_aead_demo_keys" {
  name            = var.prj_kms_keys_producer
  project_id      = var.prj_kms_keys_producer

  folder_id       = google_folder.fld_aead_encryption_demos.name
  billing_account = var.gcp_billing_id
  #   tags = {"${var.gcp_org_id}/env":"staging"}
  auto_create_network = false  # Your org can also enforces "constraints/compute.skipDefaultNetworkCreation"
}


variable "prj_aead_demo_keys_service_list" {
  description ="The list of apis needed for the Key Management project"
  type = list(string)
  default = [
    "iam.googleapis.com",
    "cloudkms.googleapis.com",
  ]
}

resource "google_project_service" "prj_aead_demo_keys_services" {
  for_each = toset(var.prj_aead_demo_keys_service_list)
  project = google_project.prj_aead_demo_keys.project_id
  service = each.key
}

# resource "google_project_iam_binding" "prj_aead_demo_keys_creator" {
#   project     = google_project.prj_aead_demo_keys.project_id
#   for_each = toset([
#     "roles/servicemanagement.quotaViewer",
#     "roles/serviceusage.serviceUsageAdmin",
#     "roles/iam.roleAdmin",
#     "roles/cloudkms.admin",
#     # "roles/cloudkms.cryptoKeyEncrypter",
#   ])
#   role        = each.key 
#   members     = [
#     "user:${var.persona_org_admin}",
#   ]
# }
