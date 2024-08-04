# Define outputs to show information about the created resources

# Output the public IP address of the load balancer
output "load_balancer_ip" {
  value = azurerm_public_ip.lb.ip_address
  description = "The public IP address of the Azure Load Balancer."
}
