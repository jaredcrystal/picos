ruleset hello_world {
  meta {
    name "Hello World"
    description << A first ruleset for the Quickstart >>
    author "Phil Windley"
    logging on
    shares hello, __testing
  }

  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
    __testing = {
      "queries": [
        { "name": "hello", "args": [ "obj" ] },
        { "name": "__testing" }
      ],
      "events": [
        { "domain": "echo", "type": "hello", "attrs": [ "name" ] },
        { "domain": "hello", "type": "name", "attrs": [ "name" ] }
      ]
    }
  }

  rule hello_world {
    select when echo hello
    pre {
      name = event:attr("name").klog("our passed in name: ")
    }
    send_directive("say") with
      something = "Hello " + name
  }

  rule store_name {
    select when hello name
    pre{
      name = event:attr("name").klog("our passed in name: ")
    }
    send_directive("store_name") with
      name = name
    always{
      ent:name := name
    }
  }

}
