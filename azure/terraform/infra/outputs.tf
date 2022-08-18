output "service_principal_tenant_id" {
  value = azuread_service_principal.service_principal.application_tenant_id
}

output "service_principal_client_id" {
  value = azuread_service_principal.service_principal.application_id
}

output "service_principal_client_secret" {
  value = azuread_service_principal_password.service_principal_password.value
}