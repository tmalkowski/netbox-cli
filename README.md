netbox-cli

Loading:
```
cp netbox-cli.init.sh.example netbox-cli.init.sh
# edit netbox-cli.init.sh and set netbox hostname + api token

# then, to use:
source $REPODIR/netbox-cli/netbox-cli.init.sh

```

Either add that to your .bash_profile, or just source it on the fly when you want to use it.


Usage:
```
# List all IP ranges: in this example, there are none present in netbox
$ netbox get /ipam/ip-ranges/ 
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": []
}

# Add a new vmware cluster: JSON object is sent in POST request body
$ netbox post /virtualization/clusters/ '{"name": "Test cluster","type":9}'
{
  "id": 13,
  "url": "https://assets.tr.txstate.edu/api/virtualization/clusters/13/",
  "display": "Test cluster",
  "name": "Test cluster",
  "type": {
    "id": 9,
    "url": "https://assets.tr.txstate.edu/api/virtualization/cluster-types/9/",
    "display": "vSphere",
    "name": "vSphere",
    "slug": "vsphere"
  },
  "group": null,
  "tenant": null,
  "site": null,
  "comments": "",
  "tags": [],
  "custom_fields": {},
  "created": "2022-06-16T09:35:51.537084-05:00",
  "last_updated": "2022-06-16T09:35:51.537115-05:00"
}


# Change an object without having to specify all the required details
$ netbox patch /virtualization/clusters/13 '{"name":"Testy test cluster"}'
{
  "id": 13,
  "url": "https://assets.tr.txstate.edu/api/virtualization/clusters/14/",
  "display": "Testy test cluster",
  "name": "Testy test cluster",
  "type": {
    "id": 9,
    "url": "https://assets.tr.txstate.edu/api/virtualization/cluster-types/9/",
    "display": "vSphere",
    "name": "vSphere",
    "slug": "vsphere"
  },
  "group": null,
  "tenant": null,
  "site": null,
  "comments": "",
  "tags": [],
  "custom_fields": {},
  "created": "2022-06-16T09:35:51.537084-05:00",
  "last_updated": "2022-06-16T09:39:15.518714-05:00",
  "device_count": 0,
  "virtualmachine_count": 0
}


# PUT method is also supported, but it requires the same fields as POST does.
# For a better understanding of when you should use PUT vs PATCH, see netbox API documentation.
# When in doubt, you probably want to use patch.
$ netbox put /virtualization/clusters/13 '{"name":"Test cluster","type":9}'
{
  "id": 13,
  "url": "https://assets.tr.txstate.edu/api/virtualization/clusters/14/",
  "display": "Test cluster",
  "name": "Test cluster",
  "type": {
    "id": 9,
    "url": "https://assets.tr.txstate.edu/api/virtualization/cluster-types/9/",
    "display": "vSphere",
    "name": "vSphere",
    "slug": "vsphere"
  },
  "group": null,
  "tenant": null,
  "site": null,
  "comments": "",
  "tags": [],
  "custom_fields": {},
  "created": "2022-06-16T09:35:51.537084-05:00",
  "last_updated": "2022-06-16T09:41:16.976494-05:00",
  "device_count": 0,
  "virtualmachine_count": 0
}


# Delete the cluster we just created (no output is returned unless there was an error)
$ netbox delete /virtualization/clusters/13



