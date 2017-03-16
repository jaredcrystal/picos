ruleset part2 {
  meta {
    name "part2"
    description << For part 2 >>
    author "Jared Crystal"
    logging on
    shares hello, __testing
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
    fired {
      raise explicit event "trip_processed"
        attributes event:attrs()
    }
  }

  rule find_long_trips {
    select when explicit trip_processed
    if (event:attr("mileage").as("Number") > long_trip.as("Number")) then
      send_directive("trip") with
        trip_length = event:attr("mileage")
      fired {
        raise explicit event "found_long_trip"
          attributes event:attrs()
      }
  }

  rule found_long_trip {
    select when explicit found_long_trip
    send_directive("trip") with
      trip_length = event:attr("mileage")
  }
}
