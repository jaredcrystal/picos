ruleset track_trips {
  meta {
    name "track_trips"
    description << For part 1 >>
    author "Jared Crystal"
    logging on
    shares hello, __testing
  }

  global {
    __testing = {
      "queries": [
        { "name": "__testing" }
      ],
      "events": [
         { "domain": "echo", "type": "message", "attrs": [ "mileage" ] }
      ]
    }
  }

  rule process_trip {
    select when echo message
    send_directive("trip") with
      trip_length = event:attr("mileage")
  }

  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      attributes = event:attrs().klog("subcription:")
    }
    always {
      raise wrangler event "pending_subscription_approval"
        attributes attributes
    }
  }
}
