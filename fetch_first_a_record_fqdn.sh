#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

eval "$(jq -r '@sh "RG=\(.resource_group_name) ZONE=\(.zone_name)"')"

az network private-dns record-set a list -z $ZONE -g $RG | jq '{"fqdn":.[0].fqdn}'

# Filtered output:
# {
#   "fqdn": "c09045d36bc3.dc-cnv-chrt-devt.np.postgres.database.azure.com."
# }

# Test input:
# {
#   "resource_group_name": "rg-uks-devt-dc-cnv-app",
#   "zone_name": "dc-cnv-chrt-devt.np.postgres.database.azure.com"
# }

# Pre filtered output looks something like this:
# [
#   {
#     "aRecords": [
#       {
#         "ipv4Address": "172.26.96.69"
#       }
#     ],
#     "aaaaRecords": null,
#     "cnameRecord": null,
#     "etag": "fc94d079-13a6-4a56-bfb9-772592740358",
#     "fqdn": "c09045d36bc3.dc-cnv-chrt-devt.np.postgres.database.azure.com.",
#     "id": "/subscriptions/0dd944af-384e-40b3-aad2-0b164916a51a/resourceGroups/rg-uks-devt-dc-cnv-app/providers/Microsoft.Network/privateDnsZones/dc-cnv-chrt-devt.np.postgres.database.azure.com/A/c09045d36bc3",
#     "isAutoRegistered": false,
#     "metadata": null,
#     "mxRecords": null,
#     "name": "c09045d36bc3",
#     "ptrRecords": null,
#     "resourceGroup": "rg-uks-devt-dc-cnv-app",
#     "soaRecord": null,
#     "srvRecords": null,
#     "ttl": 30,
#     "txtRecords": null,
#     "type": "Microsoft.Network/privateDnsZones/A"
#   }
# ]
