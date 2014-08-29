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

    # install git + xcode command line tools
    git
    # install homebrew
    ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
    # install rvm
    \curl -sSL https://get.rvm.io | bash -s stable

    brew install beanstalkd
    brew install redis
    sudo gem install bundle
    git clone git@github.com:workergnome/fakebook_api.git
    cd fakebook_api
    bundle install


    # To create a self-signed cert:
    echo "127.0.0.1 localhost.ssl" | sudo tee -a /etc/hosts
    openssl req -new -newkey rsa:2048 -sha1 -days 365 -nodes -x509 -keyout server.key -out server.crt
    mkdir ~/.ssl
	mv server.* ~/.ssl

see <http://makandracards.com/makandra/15903-using-thin-for-development-with-ssl> for more info--
see <http://makandracards.com/makandra/15901-howto-create-a-self-signed-certificate> for more info-- 