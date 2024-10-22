## Locals
locals {
  location_prefix    = substr(var.location, 0, 3)
  environment_prefix = substr(var.location, 0, 1)
  directorate        = substr(var.pdu, 0, 2)
  deputydirectorate  = substr(var.pdu, 3, 3)
  dnsenv = {
    sbox = ".np."
    devt = ".np."
    test = ".np."
    stag = "."
    prod = "."
  }
  core_vnet_id = {
    devt = "/subscriptions/67e5f2ee-6e0a-49e3-b533-97f0beec351c/resourceGroups/rg-dwp-dev-ss-core/providers/Microsoft.Network/virtualNetworks/vnet-dwp-dev-ss-core"
    test = "/subscriptions/67e5f2ee-6e0a-49e3-b533-97f0beec351c/resourceGroups/rg-dwp-dev-ss-core/providers/Microsoft.Network/virtualNetworks/vnet-dwp-dev-ss-core"
    stag = "/subscriptions/7e97df51-9a8e-457a-ab7a-7502a771bb36/resourceGroups/rg-dwp-prd-ss-core/providers/Microsoft.Network/virtualNetworks/vnet-dwp-prd-ss-core"
    prod = "/subscriptions/7e97df51-9a8e-457a-ab7a-7502a771bb36/resourceGroups/rg-dwp-prd-ss-core/providers/Microsoft.Network/virtualNetworks/vnet-dwp-prd-ss-core"
  }
  vpn_vnet_id = {
    devt = "/subscriptions/67e5f2ee-6e0a-49e3-b533-97f0beec351c/resourceGroups/rg-dwp-dev-ss-core-vpn/providers/Microsoft.Network/virtualNetworks/vnet-dwp-dev-ss-core-vpn"
    test = "/subscriptions/67e5f2ee-6e0a-49e3-b533-97f0beec351c/resourceGroups/rg-dwp-dev-ss-core-vpn/providers/Microsoft.Network/virtualNetworks/vnet-dwp-dev-ss-core-vpn"
    stag = "/subscriptions/7e97df51-9a8e-457a-ab7a-7502a771bb36/resourceGroups/rg-dwp-prd-ss-core-vpn/providers/Microsoft.Network/virtualNetworks/vnet-dwp-prd-ss-core-vpn"
    prod = "/subscriptions/7e97df51-9a8e-457a-ab7a-7502a771bb36/resourceGroups/rg-dwp-prd-ss-core-vpn/providers/Microsoft.Network/virtualNetworks/vnet-dwp-prd-ss-core-vpn"
  }
  # Routes to on premise
  private_routes = [
    {
      route_name     = "dwp-private-10.0.0.0"
      address_prefix = "10.0.0.0/8"
    },
    {
      route_name     = "dwp-private-51.0.0.0"
      address_prefix = "51.0.0.0/14"
    },
    {
      route_name     = "dwp-private-51.16.0.0"
      address_prefix = "51.16.0.0/15"
    },
    {
      route_name     = "dwp-private-51.32.0.0"
      address_prefix = "51.32.0.0/16"
    },
    {
      route_name     = "dwp-private-51.34.0.0"
      address_prefix = "51.34.0.0/15"
    },
    {
      route_name     = "dwp-private-51.38.0.0"
      address_prefix = "51.38.0.0/16"
    },
    {
      route_name     = "dwp-private-51.40.0.0"
      address_prefix = "51.40.0.0/14"
    },
    {
      route_name     = "dwp-private-51.54.0.0"
      address_prefix = "51.54.0.0/15"
    },
    {
      route_name     = "dwp-private-51.56.0.0"
      address_prefix = "51.56.0.0/14"
    },
    {
      route_name     = "dwp-private-51.60.0.0"
      address_prefix = "51.60.0.0/15"
    },
    {
      route_name     = "dwp-private-51.69.0.0"
      address_prefix = "51.68.0.0/14"
    },
    {
      route_name     = "dwp-private-51.74.0.0"
      address_prefix = "51.74.0.0/16"
    },
    {
      route_name     = "dwp-private-51.76.0.0"
      address_prefix = "51.76.0.0/16"
    },
    {
      route_name     = "dwp-private-51.78.0.0"
      address_prefix = "51.78.0.0/16"
    },
    {
      route_name     = "dwp-private-51.79.0.0"
      address_prefix = "51.79.0.0/16"
      }, {
      route_name     = "dwp-private-51.80.0.0"
      address_prefix = "51.80.0.0/16"
    },
    {
      route_name     = "dwp-private-51.82.0.0"
      address_prefix = "51.82.0.0/15"
    },
    {
      route_name     = "dwp-private-51.84.0.0"
      address_prefix = "51.84.0.0/14"
    },
    {
      route_name     = "dwp-private-51.88.0.0"
      address_prefix = "51.88.0.0/13"
    },
    {
      route_name     = "dwp-private-51.96.0.0"
      address_prefix = "51.96.0.0/14"
    },
    {
      route_name     = "dwp-private-51.100.0.0"
      address_prefix = "51.100.0.0/15"
    },
    {
      route_name     = "dwp-private-51.102.0.0"
      address_prefix = "51.102.0.0/16"
    },
    {
      route_name     = "dwp-private-51.106.0.0"
      address_prefix = "51.106.0.0/16"
    },
    {
      route_name     = "dwp-private-51.108.0.0"
      address_prefix = "51.108.0.0/15"
    },
    {
      route_name     = "dwp-private-51.110.0.0"
      address_prefix = "51.110.0.0/16"
    },
    {
      route_name     = "dwp-private-51.112.0.0"
      address_prefix = "51.112.0.0/14"
    },
    {
      route_name     = "dwp-private-51.117.0.0"
      address_prefix = "51.117.0.0/16"
    },
    {
      route_name     = "dwp-private-51.118.0.0"
      address_prefix = "51.118.0.0/15"
    },
    {
      route_name     = "dwp-private-51.121.0.0"
      address_prefix = "51.121.0.0/16"
    },
    {
      route_name     = "dwp-private-51.122.0.0"
      address_prefix = "51.122.0.0/15"
    },
    {
      route_name     = "dwp-private-51.125.0.0"
      address_prefix = "51.125.0.0/16"
    },
    {
      route_name     = "dwp-private-51.126.0.0"
      address_prefix = "51.126.0.0/15"
    },
    {
      route_name     = "dwp-private-51.128.0.0"
      address_prefix = "51.128.0.0/15"
    },
    {
      route_name     = "dwp-private-51.134.0.0"
      address_prefix = "51.134.0.0/15"
    },
    {
      route_name     = "dwp-private-51.150.0.0"
      address_prefix = "51.150.0.0/16"
    },
    {
      route_name     = "dwp-private-51.160.0.0"
      address_prefix = "51.160.0.0/16"
    },
    {
      route_name     = "dwp-private-51.164.0.0"
      address_prefix = "51.164.0.0/15"
    },
    {
      route_name     = "dwp-private-51.168.0.0"
      address_prefix = "51.168.0.0/16"
    },
    {
      route_name     = "dwp-private-51.172.0.0"
      address_prefix = "51.172.0.0/15"
    },
    {
      route_name     = "dwp-private-51.176.0.0"
      address_prefix = "51.176.0.0/16"
    },
    {
      route_name     = "dwp-private-51.184.0.0"
      address_prefix = "51.184.0.0/15"
    },
    {
      route_name     = "dwp-private-51.188.0.0"
      address_prefix = "51.188.0.0/15"
    },
    {
      route_name     = "dwp-private-51.192.0.0"
      address_prefix = "51.192.0.0/15"
    },
    {
      route_name     = "dwp-private-51.195.0.0"
      address_prefix = "51.195.0.0/16"
    },
    {
      route_name     = "dwp-private-51.197.0.0"
      address_prefix = "51.196.0.0/15"
    },
    {
      route_name     = "dwp-private-51.200.0.0"
      address_prefix = "51.200.0.0/15"
    },
    {
      route_name     = "dwp-private-51.204.0.0"
      address_prefix = "51.204.0.0/16"
    },
    {
      route_name     = "dwp-private-51.208.0.0"
      address_prefix = "51.208.0.0/15"
    },
    {
      route_name     = "dwp-private-51.212.0.0"
      address_prefix = "51.212.0.0/15"
    },
    {
      route_name     = "dwp-private-51.216.0.0"
      address_prefix = "51.216.0.0/15"
    },
    {
      route_name     = "dwp-private-51.220.0.0"
      address_prefix = "51.220.0.0/15"
    },
    {
      route_name     = "dwp-private-51.224.0.0"
      address_prefix = "51.224.0.0/15"
    },
    {
      route_name     = "dwp-private-51.228.0.0"
      address_prefix = "51.228.0.0/15"
    },
    {
      route_name     = "dwp-private-51.232.0.0"
      address_prefix = "51.232.0.0/15"
    },

    {
      route_name     = "dwp-private-51.236.0.0"
      address_prefix = "51.236.0.0/15"
    },
    {
      route_name     = "dwp-private-51.240.0.0"
      address_prefix = "51.240.0.0/16"
    },
    {
      route_name     = "dwp-private-51.244.0.0"
      address_prefix = "51.244.0.0/15"
    },
    {
      route_name     = "dwp-private-51.248.0.0"
      address_prefix = "51.248.0.0/15"
    },
    {
      route_name     = "dwp-private-51.251.0.0"
      address_prefix = "51.251.0.0/16"
    }
  ]
}
locals {
  # Next Hop IPs for rout tables
  core_firewall_ip = {
    sbox = "0.0.0.0"
    devt = "10.86.34.68"
    test = "10.86.34.68"
    stag = "10.86.146.68"
    prod = "10.86.146.68"
  }
  csr_ip = {
    sbox = "0.0.0.0"
    devt = "10.86.32.75"
    test = "10.86.32.75"
    stag = "10.86.144.75"
    prod = "10.86.144.75"
  }
  waf_address_prefix = {
    sbox = "0.0.0.0/28"
    devt = "10.86.34.96/28"
    test = "10.86.34.96/28"
    stag = "10.86.146.96/28"
    prod = "10.86.146.96/28"
  }

  # Shared Services Variables UK South
  uks_shared_services_subscription_id = {
    sbox = "67e5f2ee-6e0a-49e3-b533-97f0beec351c"
    devt = "67e5f2ee-6e0a-49e3-b533-97f0beec351c"
    test = "67e5f2ee-6e0a-49e3-b533-97f0beec351c"
    stag = "7e97df51-9a8e-457a-ab7a-7502a771bb36"
    prod = "7e97df51-9a8e-457a-ab7a-7502a771bb36"
  }
  uks_shared_services_core_vnet_name = {
    sbox = "vnet-dwp-dev-ss-core"
    devt = "vnet-dwp-dev-ss-core"
    test = "vnet-dwp-dev-ss-core"
    stag = "vnet-dwp-prd-ss-core"
    prod = "vnet-dwp-prd-ss-core"
  }
  uks_shared_services_core_vnet_resourcegroup = {
    sbox = "rg-dwp-dev-ss-core"
    devt = "rg-dwp-dev-ss-core"
    test = "rg-dwp-dev-ss-core"
    stag = "rg-dwp-prd-ss-core"
    prod = "rg-dwp-prd-ss-core"
  }
    uks_shared_services_dns_resourcegroup = {
    sbox = "rg-dwp-dev-ss-dns"
    devt = "rg-dwp-dev-ss-dns"
    test = "rg-dwp-dev-ss-dns"
    stag = "rg-dwp-prd-ss-dns"
    prod = "rg-dwp-prd-ss-dns"
  }
  uks_shared_services_firewall_vnet_name = {
    sbox = "vnet-dwp-dev-ss-core-fw"
    devt = "vnet-dwp-dev-ss-core-fw"
    test = "vnet-dwp-dev-ss-core-fw"
    stag = "vnet-dwp-prd-ss-core-fw"
    prod = "vnet-dwp-prd-ss-core-fw"
  }
  uks_shared_services_firewall_vnet_resourcegroup = {
    sbox = "rg-dwp-dev-ss-core-fw"
    devt = "rg-dwp-dev-ss-core-fw"
    test = "rg-dwp-dev-ss-core-fw"
    stag = "rg-dwp-prd-ss-core-fw"
    prod = "rg-dwp-prd-ss-core-fw"
  }
  uks_shared_services_er_vnet_name = {
    sbox = "vnet-dwp-dev-ss-core-er"
    devt = "vnet-dwp-dev-ss-core-er"
    test = "vnet-dwp-dev-ss-core-er"
    stag = "vnet-dwp-prd-ss-core-er"
    prod = "vnet-dwp-prd-ss-core-er"
  }
  uks_shared_services_er_vnet_resourcegroup = {
    sbox = "rg-dwp-dev-ss-core-er"
    devt = "rg-dwp-dev-ss-core-er"
    test = "rg-dwp-dev-ss-core-er"
    stag = "rg-dwp-prd-ss-core-er"
    prod = "rg-dwp-prd-ss-core-er"
  }
  uks_shared_services_inter_cloud_vpn_vnet_name = {
    sbox = "vnet-uks-nonp-ss-vng-core"
    devt = "vnet-uks-nonp-ss-vng-core"
    test = "vnet-uks-nonp-ss-vng-core"
    stag = "vnet-uks-prod-ss-vng-core"
    prod = "vnet-uks-prod-ss-vng-core"
  }
  uks_shared_services_inter_cloud_vpn_vnet_resourcegroup = {
    sbox = "rg-uks-nonp-ss-vng-core"
    devt = "rg-uks-nonp-ss-vng-core"
    test = "rg-uks-nonp-ss-vng-core"
    stag = "rg-uks-prod-ss-vng-core"
    prod = "rg-uks-prod-ss-vng-core"
  }
  uks_shared_services_vpn_vnet_name = {
    sbox = "vnet-dwp-dev-ss-core-vpn"
    devt = "vnet-dwp-dev-ss-core-vpn"
    test = "vnet-dwp-dev-ss-core-vpn"
    stag = "vnet-dwp-prd-ss-core-vpn"
    prod = "vnet-dwp-prd-ss-core-vpn"
  }
  uks_shared_services_vpn_vnet_resourcegroup = {
    sbox = "rg-dwp-dev-ss-core-vpn"
    devt = "rg-dwp-dev-ss-core-vpn"
    test = "rg-dwp-dev-ss-core-vpn"
    stag = "rg-dwp-prd-ss-core-vpn"
    prod = "rg-dwp-prd-ss-core-vpn"
  }
  uks_shared_services_aks_vnet_name = {
    sbox = "vnet-uks-devt-int-aks"
    devt = "vnet-uks-devt-int-aks"
    test = "vnet-uks-test-int-aks"
    stag = "vnet-uks-stag-int-aks"
    prod = "vnet-uks-prod-int-aks"
  }
  uks_shared_services_aks_vnet_resourcegroup = {
    sbox = "rg-uks-devt-int-aks"
    devt = "rg-uks-devt-int-aks"
    test = "rg-uks-test-int-aks"
    stag = "rg-uks-stag-int-aks"
    prod = "rg-uks-prod-int-aks"
  }

  # Shared Services Variables UK West
  ukw_shared_services_subscription_id = {
    sbox = "9ec8d02d-0057-4e8a-a506-c22716651c64"
    devt = "9ec8d02d-0057-4e8a-a506-c22716651c64"
    test = "9ec8d02d-0057-4e8a-a506-c22716651c64"
    stag = "7f31938e-c836-446f-80fa-8b80e21f6b2f"
    prod = "7f31938e-c836-446f-80fa-8b80e21f6b2f"
  }
  ukw_shared_services_core_vnet_name = {
    sbox = "vnet-dwp-devdr-ss-core"
    devt = "vnet-dwp-devdr-ss-core"
    test = "vnet-dwp-devdr-ss-core"
    stag = "vnet-dwp-prddr-ss-core"
    prod = "vnet-dwp-prddr-ss-core"
  }
  ukw_shared_services_core_vnet_resourcegroup = {
    sbox = "rg-dwp-devdr-ss-core"
    devt = "rg-dwp-devdr-ss-core"
    test = "rg-dwp-devdr-ss-core"
    stag = "rg-dwp-prddr-ss-core"
    prod = "rg-dwp-prddr-ss-core"
  }
  ukw_shared_services_er_vnet_name = {
    sbox = "vnet-dwp-devdr-ss-core-er"
    devt = "vnet-dwp-devdr-ss-core-er"
    test = "vnet-dwp-devdr-ss-core-er"
    stag = "vnet-dwp-prddr-ss-core-er"
    prod = "vnet-dwp-prddr-ss-core-er"
  }
  ukw_shared_services_er_vnet_resourcegroup = {
    sbox = "rg-dwp-devdr-ss-core-er"
    devt = "rg-dwp-devdr-ss-core-er"
    test = "rg-dwp-devdr-ss-core-er"
    stag = "rg-dwp-prddr-ss-core-er"
    prod = "rg-dwp-prddr-ss-core-er"
  }
  ukw_shared_services_aks_vnet_name = {
    sbox = "vnet-ukw-devt-ss-aks"
    devt = "vnet-ukw-devt-ss-aks"
    test = "vnet-ukw-test-ss-aks"
    stag = "vnet-ukw-stag-ss-aks"
    prod = "vnet-ukw-prod-ss-aks"
  }
  ukw_shared_services_aks_vnet_resourcegroup = {
    sbox = "rg-uks-devt-int-aks"
    devt = "rg-uks-devt-int-aks"
    test = "rg-dwp-test-ss-aks"
    stag = "rg-dwp-stag-ss-aks"
    prod = "rg-dwp-prod-ss-aks"
  }

  dns_forwarder_private_ip = {
    sbox = "10.88.32.30"
    devt = "10.89.32.30"
    test = "10.102.32.30"
    stag = "10.103.32.30"
    prod = "10.105.32.30"
  }

}
