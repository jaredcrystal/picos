ruleset manage_fleet {
  meta {
    name "manage fleet"
    description << For part 2 >>
    author "Jared Crystal"
    logging on
    shares __testing, vehicles, trips
    use module Subscriptions
    use module io.picolabs.pico alias stupid
  }

  global {
    vehicles = function() {
      Subscriptions:getSubscriptions()
    }
    trips = function() {
      Subscriptions:getSubscriptions()
        .filter(function(subscription){
          subscription{"attributes"}{"subscriber_role"} == "vehicle"
        }).map(function(subscription) {
          response = http:get("http://localhost:8080/sky/cloud/" + subscription{"attributes"}{"subscriber_eci"} + "/trip_store/trips");
          response{"content"}.decode()
      })
    }

    __testing = {
      "queries": [
        { "name": "vehicles" },
        { "name": "trips"}
      ],
      "events": [
        { "domain": "car", "type": "new_vehicle", "attrs": [ "name" ] },
        { "domain": "car", "type": "unneeded_vehicle", "attrs": ["name"] },
        { "domain": "car", "type": "request_report" }
      ]
    }
  }

  rule create_vehicle {
    select when car new_vehicle
    always {
      raise pico event "new_child_request"
        attributes { "dname": event:attr("name"), "color": "#54ff65", "name": event:attr("name")}
    }
  }

  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      the_vehicle = event:attr("new_child")
      vehicle_name = event:attr("rs_attrs"){"name"}
    }
    event:send({
      "eci": the_vehicle.eci,
      "eid": "install-ruleset",
      "domain": "pico",
      "type": "new_ruleset",
      "attrs": { "rid": "track_trips" }
    })
    event:send({
      "eci": the_vehicle.eci,
      "eid": "install-ruleset",
      "domain": "pico",
      "type": "new_ruleset",
      "attrs": { "rid": "trip_store" }
    })
    fired {
      ent:vehicles := ent:vehicles || {};
      ent:vehicles{[vehicle_name]} := the_vehicle;
      raise wrangler event "subscription" with
        name = vehicle_name
        name_space = "car"
        my_role = "fleet"
        subscriber_role = "vehicle"
        channel_type = "subscription"
        subscriber_eci = the_vehicle.eci
    }
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

  rule delete_vehicle {
    select when car unneeded_vehicle
    fired {
      raise pico event "delete_child_request"
        attributes ent:vehicles{event:attr("name")};
      ent:vehicles{event:attr("name")} := null;
      raise wrangler event "subscription_cancellation"
        with subscription_name = "car:" + event:attr("name")
    }
  }

  rule scatter_report {
    select when car request_report
    foreach Subscriptions:getSubscriptions() setting (subscription)
      pre {
        subs_attrs = subscription{"attributes"}
      }
      if subs_attrs{"subscriber_role"} == "vehicle" then
        event:send({
          "eci": subs_attrs{"subscriber_eci"},
          "eid": "report_needed",
          "domain": "car",
          "type": "report_needed",
          "attrs": { "eci": stupid:myself(){"eci"} }
        })
  }

  rule report {
    select when car report
    send_directive("received report") with
      trips = event:attr("trips")
  }
}
