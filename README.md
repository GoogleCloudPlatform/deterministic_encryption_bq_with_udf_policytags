# Demo: Deterministic Encryption in BigQuery with User Defined Functions (UDF) and Policy Tags

This demo covers two use cases of User Defined Functions (UDF):
1. It shows how to use UDFs directly in a BigQuery query to encrypt/decrypt data deterministically at query time.
1. It shows how Policy Tags and Data Policies use UDF as [custom Data Masking Policy routines](https://cloud.google.com/bigquery/docs/user-defined-functions#custom-mask) in BigQuery, to automatically **encrypt data deterministically at query time**, while the data is stored in clear text in the BigQuery Table.

**Determinisctic encryption** allows you to work with PII data like email addresses in an encrypted form. Users retain the ability to query, join tables and count values while they are unable to see the email addresses in clear text.

The terraform code provisions a BigQuery Dataset and a Table with PII Data in clear text. The email column is [deterministacally encrypted](https://cloud.google.com/bigquery/docs/column-key-encrypt#determine-encrypt-column) at query time. BigQuery automatically encrypts the email column by using:
* a [Policy Tag](https://cloud.google.com/bigquery/docs/column-level-security-intro#policy_tags) attached to the email column (`policytag_email`).
* a [Data Policy](https://cloud.google.com/bigquery/docs/column-data-masking-intro#data_policy_management) with
* a [Data Masking rule](https://cloud.google.com/bigquery/docs/column-data-masking-intro#masking_options) (`dp_deterministic_encrypt_STRING`) that uses
* a [Custom Masking Routine](https://cloud.google.com/bigquery/docs/user-defined-functions#custom-mask) (`custom_masking_routine_deterministically_encrypt_column`).

## Other approaches to encrypting data in BigQuery:
  * [Deterministically encrypt a column with a wrapped keyset](https://cloud.google.com/bigquery/docs/column-key-encrypt#determine-encrypt-column)
      * **Use case implemented by this architecture**. This encrypts the full content of a BigQuery column and it works automatically via *Data Masking rules*, as implemented in this architecture.
  * [DLP encryption functions](https://cloud.google.com/bigquery/docs/reference/standard-sql/dlp_functions#dlp_key_chain)
      * Similar to this architecture, however, the `DLP_DETERMINISTIC_ENCRYPT` and `DLP_DETERMINISTIC_ENCRYPT` functions cannot be used as custom *Data Masking Policy routines*. The however allow you to prepend a `surrogate` STRING value to output which can be useful when you want to anotate the encrypted value.
  * [De-identify BigQuery data at query time](https://cloud.google.com/sensitive-data-protection/docs/deidentify-bq-tutorial#considerations)
      * Encrypt only parts of the string contained in a column. This requires implementing an separate function in Cloud Run.
  * [De-identify and re-identify sensitive data](https://cloud.google.com/sensitive-data-protection/docs/inspect-sensitive-text-de-identify#reidentify)
      * Use Sensitive Data Protection to de-identify and re-identify sensitive data in text content via pseudonymization (or tokenization)

     <div style="border: 2px solid grey; padding: 10px; width: 500px;">
         TODO: Add a decision tree to choose the right approach considering pros/cons
     </div>

## Resources Provisioned

### 1. Infrastructure

tf files named as `1_*.tf` deploy the infrastructure-level resources:
  * A folder to contain the necessary projects.
  * `prj_aead_demo_bq`: A Google Cloud Project to contain the bigquery datasets and the GCS bucket.
  * `prj_aead_demo_keys`: A Google Cloud Project to contain the KMS key

### 2. Service Landing Zone

tf files named as `2_*.tf` deploy the service-level resources:
 * `gcs_fake_pii_uploads`: A Google Cloud Storage (GCS) bucket to upload a CSV file with sample PII data. The data is later transferred to the table via terraform, using the BigQuery `load_data` job. This file must be manually deleted afterwards.
 * `dataset_aead_deterministic_encrypt`: A BigQuery dataset where the table with cleartext PII data will be stored.  The `location` property must match the location of your Cloud KMS key.
+ * `dataset_udf_routines_container`: A BigQuery dataset specifically created to hold the User-Defined Function (UDF) routine `custom_masking_routine_deterministically_encrypt_column`.  Separating the UDF into its own dataset enhances granular access control over which users are allowed to access the routine.
 * `bq_aead_demo_key_ring_01`: A Google Cloud Key Management Service (KMS) Key Ring.  This is a container for the KEK (Key Encryption Key).
 * `basic_taxonomy_01`: A taxonomy to hold the Policy Tag(s). Taxonomies reflect your company's data classification strategy.
 
### 3. Application
tf files named as `3_*.tf` deploy the application-level resources:
  * `fake_pii_data`: The BigQuery table that stores the PII data.  The table schema is designed to match the sample data provided in `sample_fake_pii_data.csv`.
  * `policytag_email`: A BigQuery Policy Tag specifically assigned to the `email` column. This tag allows to apply [up to nine different *Data Policies*](https://cloud.google.com/bigquery/docs/column-data-masking-intro#roles_for_managing_taxonomies_and_policy_tags:~:text=You%20can%20create%20up%20to%20nine%20data%20policies%20for%20each%20policy%20tag.%20One%20of%20these%20policies%20is%20reserved%20for%20column%2Dlevel%20access%20control%20settings.) to the email column. Each Data Policy can apply to different groups of users.
  * `custom_masking_routine_deterministically_encrypt_column`: A custom BigQuery User-Defined Function (UDF) responsible for performing the deterministic encryption of the `email` column using the AEAD functions. This function interacts with the KMS KEK. It can be use in both, as a *Data Masking Custom routine* (user only needs access to the underlying KMS KEK) and in a normal SQL query (the user needs access to both, the underlying KMS KEK and the UDF).

## Usage

1. **Configure Variables:** Edit the `var-sample-argolis.auto.tfvars` file to set values for project ID, region, key ring name, key name, user emails for Clare and Bob, and dataset/table details.
2. **Initialize Terraform:** Run `terraform init` to initialize the working directory.
3. **Plan and Apply:** Use `terraform plan` to preview the changes and `terraform apply` to create the resources.
4. **Create a wrapped DEK Tink key:** After creating all resources via terraform, run this query as the Admin (or Data Owner) in the BQ UI to obtain a wrapped key using the KMS KEK:
~~~~sql
    SELECT
      FORMAT('%T', FROM_BASE64(TO_BASE64(
        KEYS.NEW_WRAPPED_KEYSET(
          'gcp-kms://projects/PROJECT_ID/locations/GCP_REGION/keyRings/KMS_KEY_RING_ID/cryptoKeys/KMS_KEY_ID',
          'DETERMINISTIC_AEAD_AES_SIV_CMAC_256'
        )
      ))) as wrapped_dek_keyset_bytes;
~~~~
5. **Update variable:** `wrapped_dek_keyset_bytes` with the result of the query above.
6. **Re-run Plan and Apply:** Use `terraform plan` to preview the changes and `terraform apply` to create the resources.

Use the [different personas](#BigQuery-Table-Data-Viewer-access) to test results with these queries from the BigQuery UI:
~~~~sql
    -- Test reading data - Each user will see data differently
    SELECT email, * FROM `PROJECT_ID.DATA_DATASET_ID.fake_pii_data` WHERE ssn="514-30-2668"; -- gets row with email 'jrussell@domain.com'

    -- Test using the UDF directly: Only Admin, Data Owner and Clear text Data reader can use the UDF directly.
    SELECT `PROJECT_ID.udf_routines_container.custom_masking_routine_deterministically_encrypt_column`('plaintext1');
    SELECT `PROJECT_ID.udf_routines_container.custom_masking_routine_deterministically_decrypt_column`('RESULT_FROM_ENCRYPTING_THE_STRING_ABOVE');
~~~~

## IAM Access to different resources

### BigQuery Table Data Viewer access
**Note:** Althoug all users have access to view the table data with the custom role `iam_customrole_AEAD_table_data_viewer`, each user will see the data differently based on the column's *Policy Tag* and its *Data Policies*.

Table data access is configured as follows:
  * `persona_org_admin`  can view table data in clear Text and configure the policies. This user can also use the UDF directly from the BigQuery UI.
  * `persona_data_owner` can view table data in clear Text and owns the dataset and tables. This user can also use the UDF directly from the BigQuery UI.
  * `persona_clear_text_data_reader` can view table data in clear Text. This user can also use the UDF directly from the BigQuery UI.
  * `persona_encrypted_text_data_reader` can view table data encrypted automatically, using the Data Policy `dp_deterministic_encrypt_STRING`, which uses the *custom masking rule* with the UDF `custom_masking_routine_deterministically_encrypt_column` - This user uses the UDF via the custom Data Policy and MUST NOT have access to the UDF body.
  * `persona_hashed_text_data_reader` can view table data hashed with SHA256, using the Data Policy `dp_SHA256_hash_STRING_or_BYTES`, which uses the *predefined masking rule* `SHA256` - This User does not use the UDF.

### KMS KEK Access:

This setup uses a Customer-Managed Encryption Key (CMEK), giving you full control over the key lifecycle and access management. Ensure you follow best practices for key rotation and access control. The included IAM bindings use minimal permissions and should be tailored to your specific security requirements.

#### KMS Key access is configured as follows:
  * `persona_org_admin`  Owns the keyring and can create keys
  * `persona_data_owner` can use the key to unwrap the DEK via delegation (via the BigQuery Service). Then, the DEK allows the user to decrypt any email.
  * `persona_clear_text_data_reader` can use the key to unwrap the DEK via delegation (via the BigQuery Service). The user also has access to see the UDF body, which contains the wrapped key, the DEK allows the user to decrypt any email. The user can do
  * `persona_encrypted_text_data_reader` This is a special case. The user DOES NOT NEED ACCESS TO THE UDF BODY (via  `bigquery.routines.get`), but they need access to "cloudkms.cryptoKeyVersions.useToDecryptViaDelegation" on the KEK that encrypts the DEK Tink Key.
                                         If this user gets access to the UDF body, they will see the wrapped DEK and will be able to use DETERMINISTIC_DECRYPT_STRING function to decrypt all data in the table.

* **Cloud KMS Key (KEK):** Creates a Customer-Managed Encryption Key (CMEK) `bq_aead_demo_key_01` within the Key Ring. In this setup, this key is called KEK because its purpose is to encrypt/decrypt the DEK (via AEAD encryption/decryption functions in BigQuery).

* **Cloud KMS Key IAM Binding (Encrypt Via Delegation):** Grants the specified user (e.g., a service account or a designated user) the custom role `custom_role_kms_kek_encrypt_via_delegation` on the created KEK. This allows the user to only encrypt the DEK via the BigQuery function `DETERMINISTIC_ENCRYPT`. This role should be granted judiciously.

* **Cloud KMS Key IAM Binding (Decrypt Via Delegation):** Grants the specified user (e.g., a service account or a designated user) the custom role `custom_role_kms_kek_decrypt_via_delegation` on the created KEK. This allows the user to only decrypt the DEK via the BigQuery functions [DETERMINISTIC_DECRYPT_BYTES](https://cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions#deterministic_decrypt_bytes) and [DETERMINISTIC_DECRYPT_STRING](https://cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions#deterministic_decrypt_string). This role should be granted judiciously.

## Important Considerations for AEAD Encryption in BigQuery

* **Key Wrapping:** the setup in this demo uses AEAD (Authenticated Encryption with Associated Data) functions in BigQuery. Especifically, the deterministic encryption function [DETERMINISTIC_ENCRYPT](https://cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions#deterministic_encrypt). This function uses two keys:
  * a "wrapped" Data Encryption Key (DEK), which is created manually from the Bigquery UI with [KEYS.NEW_KEYSET](https://cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions#keysnew_keyset) and
  * a Key Encryption Key (KEK), which is created in KMS by the terraform code.

* **Encryption Function:** The SQL queries will use the BigQuery AEAD function `DETERMINISTIC_ENCRYPT`, which requires both the KMS KEK and the DEK. The users running the SQL queries in this example only need `cloudkms.cryptoKeyVersions.useToDecryptViaDelegation` IAM permission over the KMS KEK.

# Disclaimer
This is not an officially supported Google product. This project is not
eligible for the [Google Open Source Software Vulnerability Rewards
Program](https://bughunters.google.com/open-source-security).

This project is intended for demonstration purposes only. It is not
intended for use in a production environment.# bq_deterministic_encryption_with_udf_policytags
