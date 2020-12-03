## Using S'Up API

### Enable the API and Token

DM the S'Up bot `set api on` and `set api token`. This will generate an API token and provide an API URL for your unique team ID.

```
Team data access via the API is on with an access token `5f31a5b2ebedbb30ef62601f9fddb56f`.
https://sup.playplay.io/api/teams/4b86006700f7565b609b620f
```

### Using Curl

Use `curl` and, optionally, `json_pp` to pretty-print the output.

```
curl -H "X-Access-Token:[token]" "https://sup.playplay.io/api/teams/[id]" | json_pp
```

### Hypermedia API

S'Up implements a [hypermedia REST API](https://restfulapi.net/hateoas/) with named links that can be followed to get team, round and user data. See [slack-sup/api/presenters](slack-sup/api/presenters) for documented fields in various models and [samples](samples) for working examples.


