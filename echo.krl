ruleset echo {
  meta {
    name "echo"
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

  rule hello {
    select when echo hello
    send_directive("say") with
      something = "Hello World"
  }

  rule message {
    select when echo message
    send_directive("say") with
      something = event:attr("input")
    }
}
