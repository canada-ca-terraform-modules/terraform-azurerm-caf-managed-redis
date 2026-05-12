locals {
  # Remove characters not permitted in Azure Managed Redis names (alphanumeric and hyphens only)
  redis_regex         = "/[^a-zA-Z0-9-]/"
  env_4               = substr(var.env, 0, 4)
  serverType_3        = substr(var.serverType, 0, 3)
  userDefinedString_7 = substr(var.userDefinedString, 0, 7)

  # SSC naming formula: {env4}{serverType3}-{userDefinedString7}
  # env4         = <dept(2)><env(1)><region(1)>  e.g. ScPc (SSC Production Canada Central)
  # serverType3  = SACM device type              e.g. CPS  (Cloud Platform Service / PaaS)
  # Full base:   ScPcCPS-myapp
  # Per-instance: base-name + "-" + instance_key e.g. ScPcCPS-myapp-primary
  # Override per instance with instance.instance_name to pin to an existing name
  base-name = replace("${local.env_4}${local.serverType_3}-${local.userDefinedString_7}", local.redis_regex, "")
}
