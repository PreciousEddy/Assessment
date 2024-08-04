# Configure Azure Security Center for the subscription
resource "azurerm_security_center_subscription_pricing" "example" {
  resource_type = "VirtualMachines"
  tier        = "Standard"
}
