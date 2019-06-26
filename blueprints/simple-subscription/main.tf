# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.28.0"
}

data "azurerm_subscription" "primary" {}

resource "azurerm_role_definition" "test" {
  name        = "${var.subscription-shortname}-sysops"
  scope       = "${data.azurerm_subscription.primary.id}"
  description = "Can monitor and restart virtual machines"

  permissions {
    actions     = [
    "Microsoft.Storage/*/read",
    "Microsoft.Network/*/read",
    "Microsoft.Compute/*/read",
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/restart/action",
    "Microsoft.Authorization/*/read",
    "Microsoft.ResourceHealth/availabilityStatuses/read",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Insights/alertRules/*",
    "Microsoft.Insights/diagnosticSettings/*",
    "Microsoft.Support/*"
    ]
    not_actions = []
  }

  assignable_scopes = [
    "${data.azurerm_subscription.primary.id}", # /subscriptions/00000000-0000-0000-0000-000000000000
  ]
}

resource "azurerm_policy_set_definition" "allowed_locations" {
  name         = "testPolicySet"
  policy_type  = "Custom"
  display_name = "Test Policy Set"

  parameters = <<PARAMETERS
    {
        "allowedLocations": {
            "type": "Array",
            "metadata": {
                "description": "The list of allowed locations for resources.",
                "displayName": "Allowed locations",
                "strongType": "location"
            }
        }
    }
PARAMETERS

  policy_definitions = <<POLICY_DEFINITIONS
    [
        {
            "parameters": {
                "listOfAllowedLocations": {
                    "value": "[parameters('allowedLocations')]"
                }
            },
            "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
        }
    ]
POLICY_DEFINITIONS
}

resource "azurerm_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  scope                = "${data.azurerm_subscription.primary.id}"
  policy_definition_id = "${azurerm_policy_set_definition.allowed_locations.id}"
  description          = "Policy Assignment created via an Acceptance Test"
  display_name         = "Allowed locations assignment created by terraform"

  parameters = <<PARAMETERS
{
  "allowedLocations": {
    "value": ${var.allowedLocations}
  }
}
PARAMETERS
}