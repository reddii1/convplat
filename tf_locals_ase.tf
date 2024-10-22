# Routes to on premise

locals {
  ase_routes = [
    {
      route_name     = "ase-mgmt-70.37.57.58"
      address_prefix = "70.37.57.58/32"
    },
    {
      route_name     = "ase-mgmt-157.55.208.185"
      address_prefix = "157.55.208.185/32"
    },
    {
      route_name     = "ase-mgmt-52.174.22.21"
      address_prefix = "52.174.22.21/32"
    },
    {
      route_name     = "ase-mgmt-13.94.149.179"
      address_prefix = "13.94.149.179/32"
    },
    {
      route_name     = "ase-mgmt-13.94.143.126"
      address_prefix = "13.94.143.126/32"
    },
    {
      route_name     = "ase-mgmt-13.94.141.115"
      address_prefix = "13.94.141.115/32"
    },
    {
      route_name     = "ase-mgmt-52.178.195.197"
      address_prefix = "52.178.195.197/32"
    },
    {
      route_name     = "ase-mgmt-52.178.190.65"
      address_prefix = "52.178.190.65/32"
    },
    {
      route_name     = "ase-mgmt-52.178.184.149"
      address_prefix = "52.178.184.149/32"
    },
    {
      route_name     = "ase-mgmt-52.178.177.147"
      address_prefix = "52.178.177.147/32"
    },
    {
      route_name     = "ase-mgmt-13.75.127.117"
      address_prefix = "13.75.127.117/32"
    },
    {
      route_name     = "ase-mgmt-40.83.125.161"
      address_prefix = "40.83.125.161/32"
    },
    {
      route_name     = "ase-mgmt-40.83.121.56"
      address_prefix = "40.83.121.56/32"
    },
    {
      route_name     = "ase-mgmt-40.83.120.64"
      address_prefix = "40.83.120.64/32"
    },
    {
      route_name     = "ase-mgmt-52.187.56.50"
      address_prefix = "52.187.56.50/32"
      }, {
      route_name     = "ase-mgmt-52.187.63.37"
      address_prefix = "52.187.63.37/32"
    },
    {
      route_name     = "ase-mgmt-52.187.59.251"
      address_prefix = "52.187.59.251/32"
    },
    {
      route_name     = "ase-mgmt-52.187.63.19"
      address_prefix = "52.187.63.19/32"
    },
    {
      route_name     = "ase-mgmt-52.165.158.140"
      address_prefix = "52.165.158.140/32"
    },
    {
      route_name     = "ase-mgmt-52.165.152.214"
      address_prefix = "52.165.152.214/32"
    },
    {
      route_name     = "ase-mgmt-52.165.154.193"
      address_prefix = "52.165.154.193/32"
    },
    {
      route_name     = "ase-mgmt-52.165.153.122"
      address_prefix = "52.165.153.122/32"
    },
    {
      route_name     = "ase-mgmt-104.44.129.255"
      address_prefix = "104.44.129.255/32"
    },
    {
      route_name     = "ase-mgmt-104.44.134.255"
      address_prefix = "104.44.134.255/32"
    },
    {
      route_name     = "ase-mgmt-104.44.129.243"
      address_prefix = "104.44.129.243/32"
    },
    {
      route_name     = "ase-mgmt-104.44.129.141"
      address_prefix = "104.44.129.141/32"
    },
    {
      route_name     = "ase-mgmt-23.102.188.65"
      address_prefix = "23.102.188.65/32"
    },
    {
      route_name     = "ase-mgmt-191.236.154.88"
      address_prefix = "191.236.154.88/32"
    },
    {
      route_name     = "ase-mgmt-13.64.115.203"
      address_prefix = "13.64.115.203/32"
    },
    {
      route_name     = "ase-mgmt-65.52.193.203"
      address_prefix = "65.52.193.203/32"
    },
    {
      route_name     = "ase-mgmt-70.37.89.222"
      address_prefix = "70.37.89.222/32"
    },
    {
      route_name     = "ase-mgmt-52.224.105.172"
      address_prefix = "52.224.105.172/32"
    },
    {
      route_name     = "ase-mgmt-23.102.135.246"
      address_prefix = "23.102.135.246/32"
    },
    {
      route_name     = "ase-mgmt-52.225.177.153"
      address_prefix = "52.225.177.153/32"
    },
    {
      route_name     = "ase-mgmt-65.52.172.237"
      address_prefix = "65.52.172.237/32"
    },
    {
      route_name     = "ase-mgmt-52.151.25.45"
      address_prefix = "52.151.25.45/32"
    },
    {
      route_name     = "ase-mgmt-40.124.47.188"
      address_prefix = "40.124.47.188/32"
    },
    {
      route_name     = "ase-mgmt-13.66.140.0"
      address_prefix = "13.66.140.0/32"
    },
    {
      route_name     = "ase-mgmt-13.69.64.128"
      address_prefix = "13.69.64.128/32"
    },
    {
      route_name     = "ase-mgmt-13.69.227.128"
      address_prefix = "13.69.227.128/32"
    },
    {
      route_name     = "ase-mgmt-13.67.8.128"
      address_prefix = "13.67.8.128/32"
    },
    {
      route_name     = "ase-mgmt-13.70.73.128"
      address_prefix = "13.70.73.128/32"
    },
    {
      route_name     = "ase-mgmt-13.71.170.64"
      address_prefix = "13.71.170.64/32"
    },
    {
      route_name     = "ase-mgmt-13.71.194.129"
      address_prefix = "13.71.194.129/32"
    },
    {
      route_name     = "ase-mgmt-13.77.50.128"
      address_prefix = "13.77.50.128/32"
    },
    {
      route_name     = "ase-mgmt-13.89.171.0"
      address_prefix = "13.89.171.0/32"
    },
    {
      route_name     = "ase-mgmt-20.36.106.128"
      address_prefix = "20.36.106.128/32"
    },
    {
      route_name     = "ase-mgmt-20.36.114.64"
      address_prefix = "20.36.114.64/32"
    },
    {
      route_name     = "ase-mgmt-23.100.226.236"
      address_prefix = "23.100.226.236/32"
    },
    {
      route_name     = "ase-mgmt-40.69.106.128"
      address_prefix = "40.69.106.128/32"
    },
    {
      route_name     = "ase-mgmt-40.70.146.128"
      address_prefix = "40.70.146.128/32"
    },
    {
      route_name     = "ase-mgmt-40.71.13.64"
      address_prefix = "40.71.13.64/32"
    },
    {
      route_name     = "ase-mgmt-40.74.100.64"
      address_prefix = "40.74.100.64/32"
    },
    {
      route_name     = "ase-mgmt-40.78.194.128"
      address_prefix = "40.78.194.128/32"
    },

    {
      route_name     = "ase-mgmt-40.79.130.64"
      address_prefix = "40.79.130.64/32"
    },
    {
      route_name     = "ase-mgmt-40.90.240.166"
      address_prefix = "40.90.240.166/32"
    },
    {
      route_name     = "ase-mgmt-40.91.126.196"
      address_prefix = "40.91.126.196/32"
    },
    {
      route_name     = "ase-mgmt-40.112.242.192"
      address_prefix = "40.112.242.192/32"
    },
    {
      route_name     = "ase-mgmt-40.119.4.111"
      address_prefix = "40.119.4.111/32"
    },
    {
      route_name     = "ase-mgmt-51.140.146.64"
      address_prefix = "51.140.146.64/32"
    },
    {
      route_name     = "ase-mgmt-51.140.210.128"
      address_prefix = "51.140.210.128/32"
    },
    {
      route_name     = "ase-mgmt-52.162.80.89"
      address_prefix = "52.162.80.89/32"
    },
    {
      route_name     = "ase-mgmt-52.162.106.192"
      address_prefix = "52.162.106.192/32"
    },
    {
      route_name     = "ase-mgmt-52.231.18.64"
      address_prefix = "52.231.18.64/32"
    },
    {
      route_name     = "ase-mgmt-52.231.146.128"
      address_prefix = "52.231.146.128/32"
    },
    {
      route_name     = "ase-mgmt-65.52.14.230"
      address_prefix = "65.52.14.230/32"
    },
    {
      route_name     = "ase-mgmt-104.43.242.137"
      address_prefix = "104.43.242.137/32"
    },
    {
      route_name     = "ase-mgmt-104.208.54.11"
      address_prefix = "104.208.54.11/32"
    },
    {
      route_name     = "ase-mgmt-104.211.81.64"
      address_prefix = "104.211.81.64/32"
    },
    {
      route_name     = "ase-mgmt-104.211.146.128"
      address_prefix = "104.211.146.128/32"
    },
    {
      route_name     = "ase-mgmt-104.214.49.0"
      address_prefix = "104.214.49.0/32"
    },
    {
      route_name     = "ase-mgmt-157.55.176.93"
      address_prefix = "157.55.176.93/32"
    },
    {
      route_name     = "ase-mgmt-191.233.203.64"
      address_prefix = "191.233.203.64/32"
    },
    {
      route_name     = "ase-mgmt-51.140.203.121"
      address_prefix = "51.140.203.121/32"
    },
    {
      route_name     = "ase-mgmt-51.140.185.75"
      address_prefix = "51.140.185.75/32"
    }
  ]
}
