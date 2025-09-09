# netbox-cli

## Loading

```
cp netbox-cli.init.sh.example netbox-cli.init.sh
```
Then edit netbox-cli.init.sh and set netbox hostname + api token.

To add netbox cli function to your active, shell, source the init script:
```
source $REPODIR/netbox-cli.init.sh
```

You can also add that to your .bash_profile; personally, I just source the file in whatever shell I need it in.

`netbox` has full bash completion support for API method + path.


## Usage + Examples

### Tab Completion

Tab completion is nice:
```
$ netbox [tab][tab]
delete  get     patch   post    put     
```
```
$ netbox get /[tab][tab]
/circuits/circuit-terminations/       /dcim/device-bays/                    /dcim/manufacturers/
/dcim/rack-reservations/              /extras/custom-links/                 /ipam/fhrp-group-assignments/
/ipam/vrfs/                           /users/users/                         /circuits/circuit-types/
/dcim/device-roles/                   /dcim/module-bay-templates/           /dcim/rack-roles/
... (there are a lot more, but you get the idea)
```

Paths are only 3 levels deep in netbox api, e.g. /virtualization/clusters/7

The full set of choices for the first two path components can be built from the API (e.g. GET /api/, GET /api/circuits/, GET /api/dcim/, etc).

This data is stored in a local cache file, and rebuilt periodically.

```
$ netbox get /circuits/[tab][tab]
/circuits/circuit-terminations/  /circuits/circuit-types/         
/circuits/circuits/              /circuits/provider-networks/     /circuits/providers/             
...
```

### GET (show available sub-paths, list all matching objects, or list a specific object)

List all IP ranges: in this example, we don't have any IP ranges defined
```
$ netbox get /ipam/ip-ranges/ 
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": []
}
```

### Using filters to find objects

Filters are just query string parameters. There are two ways to do this, and they are both identical.

Method 1: extra cli argument contains query string
```
$ netbox get /extras/tags/ slug=dept-clas
```
Method 2: add query string to URL path
```
$ netbox get /extras/tags/?slug=dept-clas
```

Either way, the results will include the tag we're looking for.
```
$ netbox get /extras/tags/ slug=dept-clas
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 54,
      "url": "https://netbox.example.com/api/extras/tags/54/",
      "display": "Department: Conslng, Ldrship, Adlt Educ & Schl Psych",
      "name": "Department: Conslng, Ldrship, Adlt Educ & Schl Psych",
      "slug": "dept-clas",
      "color": "673ab7",
      "description": "",
      "tagged_items": 0,
      "created": "2022-06-15T13:19:20.007840-05:00",
      "last_updated": "2022-06-15T13:19:20.007857-05:00"
    }
  ]
}
```


### POST (create a new object)

Add a new vmware cluster: JSON object is sent in POST request body
```
$ netbox post /virtualization/clusters/ '{"name": "Test cluster","type":9}'
{
  "id": 13,
  "url": "https://netbox.example.com/api/virtualization/clusters/13/",
  "display": "Test cluster",
  "name": "Test cluster",
  "type": {
    "id": 9,
    "url": "https://netbox.example.com/api/virtualization/cluster-types/9/",
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
```

### PATCH (modify a particular field on an object)

Change an object without having to specify all the required details:
```
$ netbox patch /virtualization/clusters/13 '{"name":"Testy test cluster"}'
{
  "id": 13,
  "url": "https://netbox.example.com/api/virtualization/clusters/14/",
  "display": "Testy test cluster",
  "name": "Testy test cluster",
  "type": {
    "id": 9,
    "url": "https://netbox.example.com/api/virtualization/cluster-types/9/",
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
```

### PUT

PUT method is also supported, but it requires the same fields as POST does.

For a better understanding of when you should use PUT vs PATCH, see netbox API documentation.

(When in doubt, you probably want to use patch.)

```
$ netbox put /virtualization/clusters/13 '{"name":"Test cluster","type":9}'
{
  "id": 13,
  "url": "https://netbox.example.com/api/virtualization/clusters/14/",
  "display": "Test cluster",
  "name": "Test cluster",
  "type": {
    "id": 9,
    "url": "https://netbox.example.com/api/virtualization/cluster-types/9/",
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
```

### DELETE
Delete the cluster we just created (no output is returned unless there was an error)
```
$ netbox delete /virtualization/clusters/13
```
