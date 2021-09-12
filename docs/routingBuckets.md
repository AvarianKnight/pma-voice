## Routing Buckets

pma-voice supports routing buckets, but it cannot directly do this as there are no events for routing bucket updates.

This means when you update a players routing bucket you will need to call [updateRoutingBucket](server-setters/updateRoutingBucket.md)

You can also directly set this using state bags [as can bee seen here](state-getters/stateBagGetters.md#example-for-setting-routing-buckets)
