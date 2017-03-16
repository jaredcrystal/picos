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
        { "domain": "echo", "type": "hello" },
        { "domain": "echo", "type": "message", "attrs": [ "input" ] }
      ]
    }
  }

  rule process_trips {
    select when echo hello
    send_directive("say") with
      something = "Hello World"
  }
}
