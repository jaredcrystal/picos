ruleset trip_store {
  meta {
    name "trip_store"
    description << For part 3 >>
    author "Jared Crystal"
    logging on
    shares hello, __testing, trips, long_trips, short_trips
    provides trips, long_trips, short_trips
  }

  global {
    __testing = {
      "queries": [
        { "name": "__testing" },
        { "name": "trips" },
        { "name": "long_trips" },
        { "name": "short_trips" }
      ],
      "events": [
         { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage" ] },
         { "domain": "explicit", "type": "found_long_trip", "attrs": [ "mileage" ] },
         { "domain": "car", "type": "trip_reset" }
      ]
    }
    trips = function() {
      ent:trips
    }
    long_trips = function() {
      ent:long_trips
    }
    short_trips = function() {
      ent:trips.filter(function(x){ x{"mileage"} < 100 })
    }
  }

  rule collect_trips {
    select when explicit trip_processed
    pre {
      mileage = event:attr("mileage").as("Number")
      timestamp = event:attr("timestamp")
    }
    always {
      ent:trips := ent:trips.append({"timestamp": timestamp, "mileage": mileage})
    }
  }

  rule collect_long_trips {
    select when explicit found_long_trip
    pre {
      mileage = event:attr("mileage").as("Number")
      timestamp = event:attr("timestamp")
    }
    always {
      ent:long_trips := ent:long_trips.append({"timestamp": timestamp, "mileage": mileage})
    }
  }

  rule clear_trips {
    select when car trip_reset
    always {
      ent:trips := [];
      ent:long_trips := []
    }
  }
}
