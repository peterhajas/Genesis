TODO: Write me up

Networking
############

Systems
=======

There are 3 machines involved in a typical interaction: Builder, Mediator, and
Editor.

* Builder is the program installed on a desktop machine by the user that performs
  the actual compiling/running/testing of the software. This allows the user to
  keep his/her full software stack and avoids sandboxing/DoS attacks for us.
* Editor is the client that edits source code (eg - iOS client). It is commands
  the builder to perform various actions.
* Mediator is the server that facilitates the communication between the Builder
  and Editor. The mediator avoids the issue of having to do port forwarding.
  The current version makes the mediator also transfers all data between the
  Builder and Editor. In the future, it would be prefered to simply use the
  Mediator as a NAT-punchthrough service.

Format
=============

This is a relatively simple format to support the most flexibility. This makes
the protocol suffer from size. (Maybe rewrite it after the API stablizes?).

The current implementation suffers from:

* *No binary file support.* JSON does not support transferring binary data.
* *Limited file size support.* No easy way to stream JSON data, so all file contents
  should be able to fit in memory before being written to disk

Version
-------

When connecting to the socket server, the first number returned is always the
version:

    <version>

Where version is an unsigned short (2-bytes) in network byte order.

It is the client's job to check if it supports the given version and close if
the version is invalid. The mediator may close the connection for an invalid
request and other clients will simply return errors for invalid requests sent
to them.


Message
-------

Each message is in the form:

    <len><data>

Where len is the number of bytes of data, represented as an unsigned short in
network byte-order. Data is zlibbed JSON data. Data is in the JSON-RPC version
1 format:

    // Request format
    {
        "method": "login",
        "params": ["jeff", "hash_pwd", "terminator", "editor.iOS", 0],
        "id": 1
    }

    // Response format
    {
        "id": 1,
        "result": {},
        "error": null
    }

Where name is a string, properties is an object. It is possible for clients
to receive either a Request or Response.


Commands
==============

It's worth noting an additional argument to all commands, the sender argument.
In most cases, it is simply 0 and always is the last argument. This is modified
by the Mediator to indicate where the given message originates from when using
the SEND or REQUEST commands.

Commands Supported by Build Server
----------------------------------

Various commands a builder server manages. It is assumed that only one PERFORM or
GIT operation can be active at a time, per project. The current implementation
assumes only one client sending commands to the server.

All these commands return responses.

* project() - Lists all available projects on the system.

* files(project) - Lists all files & metadata for the project

* download(project, filepath) - Downloads the given file. All data downloaded is
  assumed to be plain/text.

* stats() - Gives current stats of the build server. Currently only supports
  one property right now:

  * activity - Indicates the task being performed. Dictionary of project => name,
    where name is the value given in PERFORM or just 'GIT*' if running a
    GIT command. Is null if there is no streaming command running.

* perform(project, name) - Perform action on project. Usually is
  BUILD, RUN, and TEST. Name can only be alphanumeric.
  Streams stdout and stderr back to sender.

* upload(from_machine, project, rel_filepath, data) - Uploads file to build
  server. All files are relative to project root (no parent directories
  allowed). All data is currently assumed to be plain/text.

* git(from_machine, command?) - Runs a git command ? (TODO: be more specific)
  Streams stdout and stderr back to sender.

* cancel(from_machine, project) - Cancels operation from the last streaming
  command sent to the builder (from GIT or PERFORM)

* input(from_machine, project, input_string) - Sends standard input data.
  Newlines are NOT automatically append.

Commands Supported by Mediator
------------------------------

* register(email, password) - Registers a given username and password on
  the mediator. After registering, you must log in.

  Once logged in, this command is no longer functional.

* login(email, password, machine, type) - Logs user in to mediator. Shows
  clients only avaliable only to that particular user (like a namespace).

  Machine name should be a unique identifier. Type indicates the kind of
  machine to connect to.

  This is a prereq for all other commands except for REGISTER.


* send(machine, command) - Sends the given command (JSON object) to the given
  machine name. Mediator will append the sender information.

  Essentially pipes a command to another machine connected to the mediator.
  *No response is given by the mediator*


* request(machine, command) - Idential to SEND, except the response given is
  from the target machine the message is being sent to.

* clients() - Returns all builders and clients connected to mediator under
  the current user's account with their associated machine names and types.


Streaming Commands (Should be supported by Editor/Client)
---------------------------------------------------------

[allows accepting streaming output from a given command]

* stream(from_machine, project, contents) - Incoming data that the build server
  reports when doing a PERFORM or GIT. This is both stdout & stderr

* stream_eof(from_machine, project) - Indicates end of stream of PERFORM or GIT

* return(from_machine, project, code) - Indicates return code from PERFORM or GIT

