ruleset manage_fleet {
  meta {
    name "manage fleet"
    description << For part 2 >>
    author "Jared Crystal"
    logging on
    shares __testing, vehicles
    use module Subscriptions
  }

  global {
    vehicles = function() {
      Subscriptions:getSubscriptions()
    }
    __testing = {
      "queries": [
        { "name": "vehicles" }
      ],
      "events": [
        { "domain": "car", "type": "new_vehicle", "attrs": [ "name" ] },
        { "domain": "car", "type": "unneeded_vehicle", "attrs": ["name"] }
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
      "eci": the_vehicle.eci, "eid": "install-ruleset",
      "domain": "pico", "type": "new_ruleset",
      "attrs": { "rid": "track_trips" }
    })
    event:send({
      "eci": the_vehicle.eci, "eid": "install-ruleset",
      "domain": "pico", "type": "new_ruleset",
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
}
