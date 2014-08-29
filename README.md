### Todo:

* search for local event
* join event
* invite friend to event
* send message
* Need to use a template for the status bars
* Need to add timestamps and timeouts to jobs


### Notes: 

Unfriend is not confirming.

#### Done:

* DONE - authenticate
* DONE - add friend
* DONE - unfriend
* DONE - block
* DONE - unblock
* DONE - post on wall
* DONE - poke

### install:

    # install git
    # install homebrew
    # install rvm
    brew install beanstalkd
    brew install redis
    
    # To create a self-signed cert:
    openssl req -new -newkey rsa:2048 -sha1 -days 365 -nodes -x509 -keyout server.key -out server.crt

see <http://makandracards.com/makandra/15901-howto-create-a-self-signed-certificate> for more info