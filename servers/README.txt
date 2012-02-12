TODO: Write me up

just some basic terminology used through out the code:

* Build server: Server that builds and runs the code. This is installed on
    the user's machine. Currently, this will behave more like a client than
    an actual server.
* Mediator: The server that facilitates the communication between the iOS
    client and Build Server
* Backend: The communication between the build server and mediator
* Frontend: The communication between the mediator and iOS client

Networking
############

Format
=============

This is a relatively simple format to support the most flexibility. A rewrite
that keeps it smaller may be done later.

Version
-------

When connecting to the socket server, the first number returned is always the
version:

    <version>

Where version is an unsigned 32-bit integer.

It is the client's job to check if it supports the given version and close if
the version is invalid. The mediator and other clients may return errors back
to the client with an invalid version.

Message
-------

Each message is in the form:

    <len> <data>

Where len is the number of bytes of data, represented as an uint64. Data is 
GZipped JSON data. Messages are in the JSON format of:

    [name, properties]

Where name is a string, properties is an object.

Commands
==============

Commands Supported by Build Server
----------------------------------

* PROJECTS() - Lists all available projects on the system.
** ["OK", {"projects": [{"name": "MyProject"}]}]
** ["FAIL", {"reason": "...", "code": 1] where error codes:
*** 0 - Internal Server Error
*** 1 - Bad Request

* FILES(project) - Lists all files & metadata for the project
** ["OK", {"files": [{"myfile.py": {"size": 123, "kind": "code"}]}]
** ["FAIL", {"reason": "...", "code": 1] where error codes:
*** 0 - Internal Server Error
*** 1 - Bad Request

* DOWNLOAD(project, filepath) - Downloads the given file
* STATS() - Gives current stats of the build server. Currently only supports
    one property right now:
** activity - Indicates the task being performed. Dictionary of project => name,
        where name is the value given in PERFORM or just 'GIT*' if running a
        GIT command.

* PERFORM(stream_to, project, name) - Perform action on project. Usually is
    BUILD, RUN, and TEST. Name can only be alphanumeric.
    stream_to should be a machine to stream stdout and stderr data to.

* UPLOAD(from_machine, project, rel_filepath, data) - Uploads file to build server
* GIT(from_machine, command?) - Runs a git command ? (TODO: be more specific)
* CANCEL(from_machine, project) - Cancels operation from last command
* INPUT(from_machine, project, input_string) - Sends std

Commands Supported by Mediator
------------------------------

* REGISTER(user, pwd) - Registers a given username and password on
    the mediator. After registering, you must log in.

    Types of response are:
** ["OK", {}] - for valid registration.
** ["FAIL", {"reason": "...", "code": 1} - error state with the following
        kinds of error codes:
*** 0 - Internal Server Error
*** 1 - Bad Request
*** 100 - Username already in use
*** 101 - Invalid username format
*** 102 - Invalid password format

* LOGIN(user, pwd, machine, type) - Logs user in to mediator. Shows
    clients only avaliable only to that particular user (like a namespace).
    Machine name should be a unique identifier. Type indicates the kind of
    machine to connect to.
    This is a prereq for all other commands except for REGISTER.

    Types of response are:
** ["OK", {}] - for valid credentials
** ["FAIL", {"reason": "...", "code": 1} - error state with the following
        kinds of error codes:
*** 0 - Internal Server Error
*** 1 - Bad Request
*** 100 - Bad authentication credentials
*** 101 - Machine name conflict
*** 102 - Bad machine format
*** 103 - Bad type format

* SEND(machine, command) - Sends the given command_body to the given
    machine name. The machine should be a build server. Send will assign
    from to command where from = the originator's machine name.

    Essentially pipes a command to another machine connected to the mediator.
    Returns the response that the given machine returns. But can return
    and error form:

** ["FAIL", {"reason": "...", "from_machine": "-mediator", "code": 1}]
        Where error codes mean:
*** 0 - Internal Server Error
*** 1 - Bad Request
*** 100 - Unknown machine name
*** 101 - Machine timed out

* CLIENTS() - Returns all builders and clients connected to mediator under
    the current user's account with their associated machine names and types.

    Returns one of the following responses:
** ["OK", {"clients": {"MyBuilder": "builder"}} - Where clients is a dictionary
        of machine names mapped to machine types.
** ["FAILED", {"reason": "...", "code": 1}] - Where error codes are:
*** 0 - Internal Server Error
*** 1 - Bad Request


Commands Supported by Client (TCP here, may change to HTTP?)
------------------------------------------------------------

[allows accepting streaming output from a given command]

* STREAM(from_machine, project, contents) - Incoming data that the build server
    reports when doing a PERFORM or GIT. This is both stdout & stderr
* STREAM_EOF(from_machine, project) - Indicates end of stream of PERFORM or GIT
* RETURN(from_machine, project, code) - Indicates return code from PERFORM or GIT

