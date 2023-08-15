output function_zip_blob_url {
  description = "Azure Function Zip Source File in Blob Storage"
  value       = "${azurerm_storage_blob.this.url}${data.azurerm_storage_account_blob_container_sas.this.sas}"
}