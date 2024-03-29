ruleset track_trips {
  meta {
    name "track_trips"
    description << For part 2 >>
    author "Jared Crystal"
    logging on
    shares hello, __testing
    use module trip_store
  }

  global {
    long_trip = 100
    __testing = {
      "queries": [
        { "name": "__testing" }
      ],
      "events": [
         { "domain": "car", "type": "new_trip", "attrs": [ "mileage" ] },
         { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage" ] },
         { "domain": "explicit", "type": "find_long_trips", "attrs": [ "mileage" ] },
         { "domain": "explicit", "type": "found_long_trip", "attrs": [ "mileage" ] }
      ]
    }
  }

  rule process_trip {
    select when car new_trip
    send_directive("trip") with
      trip_length = event:attr("mileage")
      trip_time = time:now()
    fired {
      raise explicit event "trip_processed"
        attributes {"mileage": event:attr("mileage"), "timestamp": time:now()}
    }
  }

  rule find_long_trips {
    select when explicit trip_processed
    pre {
      attrs = {"mileage": event:attr("mileage"), "timestamp": time:now()}
    }
    if (event:attr("mileage").as("Number") > long_trip.as("Number")) then
      noop()
    fired {
      raise explicit event "found_long_trip"
        attributes attrs
    }
  }

  rule found_long_trip {
    select when explicit found_long_trip
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
      // raise wrangler event "subscription" with
      //   name = vehicle_name
      //   name_space = "car"
      //   my_role = "fleet"
      //   subscriber_role = "vehicle"
      //   channel_type = "subscription"
      //   subscriber_eci = the_vehicle.eci
    }
  }

  rule report_needed {
    select when car report_needed
    pre {
      thing = event:attr("eci").klog("eci: ")
    }
    event:send({
      "eci": event:attr("eci"),
      "eid": "report",
      "domain": "car",
      "type": "report",
      "attrs": { "trips": trip_store:trips(), "uid": event:attr("uid") }
    })
  }
}
