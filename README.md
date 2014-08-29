## Fakebook API

This is a system designed to allow server-side access to Facebook using [Capybara](https://github.com/jnicklas/capybara) and [PhantomJS](http://phantomjs.org). It's still deeply experimental; it may or may not work at any point.

Also, it's a *terrible idea*. It involves giving your Facebook password to random software to be transmitted over the internet and to be stored in plain text on the computer.  

This should make you nervous.

Please notice that Facebook's [Terms of Service](https://www.facebook.com/legal/terms) forbid doing anything like this — there's a very good chance using this will result in Facebook banning your account.  Use a fake account.  Note that  Facebook's [Terms of Service](https://www.facebook.com/legal/terms) forbid fake accounts. 

Use at your own risk.

## Installation: 

This requires [Redis](http://redis.io), [beanstalkd](http://kr.github.io/beanstalkd/), and [PhantomJS](http://phantomjs.org) to be installed on your system.

    git clone https://github.com/workergnome/fakebook_api.git
    cd fakebook_api
    bundle install
    
Note that currently, the software assumes that you have a self-signed SSL certificate located at `~/.ssl/localhost.ssl`. 

See the [Wiki Installation](https://github.com/workergnome/fakebook_api/wiki/Install-Instructions) for more detailed instructions.


## Usage Instructions:

For development purposes, the system is currently designed to use [Foreman](https://github.com/ddollar/foreman) to handle starting everything up.

    foreman start

Will initialize the application.

Additionally, for debugging, the background job runner is commented out of the `Procfile`.  You can either comment it back in or you can, in a second terminal:

    bundle exec ruby lib/background_task.rb

If you need additional debug information, you can either `export DEBUG=1` or create a `.env` file in the root directory.  This will set **PhantomJS** into verbose mode.

Once the application is running, go to <https://localhost:3000/>.  You'll see a form that will allow you do test the service.

Additionally, you can post data to the following endpoints:

* <https://localhost:3000/poke>
* <https://localhost:3000/post>
* <https://localhost:3000/friend>
* <https://localhost:3000/unfriend>
* <https://localhost:3000/block>
* <https://localhost:3000/unblock>

You will need to provide the following form fields:


    email:    "your@emailaddress.com"
    password: "yourFacebookPassword"
    message:  "An optional message for posting on the wall of your friend"
    id:       "your_friends_fb_id"

Once you submit a request, you will receive a ticket in the form of a UUID:  something like `5aab4905-0fe9-4352-a0e6-0d93d7d0f760`

You can check on the status of the request by going to <https://localhost:3000/pretty_status/5aab4905-0fe9-4352-a0e6-0d93d7d0f760> (or <https://localhost:3000/status/5aab4905-0fe9-4352-a0e6-0d93d7d0f760> for JSON)

It usually takes about 30 seconds for a request to be completed, and they will queue up in order.  Theoretically, you can run multiple workers to handle multiple requests in order—that hasn't been tested yet.

A log file will be created in the `/logs` directory with the UUID as a filename.  This will show the status of the request.  If it fails for any reason, it will create a screenshot of the webpage in the `/screenshots` directory of the page at the point where it failed.

#### A Brief Digression.

Facebook has some of the worst CSS I've ever had the opportunity to scrape.  It's obviously highly generated, inconsistent, it uses multiple identical IDs, and it's generally obnoxious.   

It's almost like they don't *want*  anyone to scrape and automate their site. 


----

This is under active development—things will change, things will break, etc.  I'd say that you shouldn't use this in production, but there are basically no places where this would be useful in production, and if you can think of one, **stop thinking about that.**

