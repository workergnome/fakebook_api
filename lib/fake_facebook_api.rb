require 'capybara'
require 'capybara/poltergeist'
require 'securerandom'

# Use a .env file to pull environment vars
require 'dotenv'
Dotenv.load

#------------------------------------------------------------------#
#  Generic error class—used so that facebook errors can be caught
#  and screenshots taken.
#------------------------------------------------------------------#
class FacebookError < StandardError
end


#------------------------------------------------------------------#
#  Actual Facebook API Class.    
# 
#------------------------------------------------------------------#

class FakeFacebookApi
  attr_accessor :email, :password, :ticket
  def FakeFacebookApi.allowable_routes
    ["/friend", "/unfriend", "/poke", "/post", "/join_event", "/block", "/unblock", "/login"]
  end


  #----------------------------------------------------------------#
  # For initialization, pass in the email, password, and ticket.
  # Additionally, if you pass in headless=true, it will run using
  # Selenium instead of poltergeist, so you can see the behaviour.
 
  def initialize(email, password, ticket, headless = false)
    @email = email
    @password = password
    @ticket = ticket
    if headless
      Capybara.run_server = false
      Capybara.default_wait_time = 5

      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(app, {:debug => (ENV['DEBUG'] || false)})
      end
      @session = Capybara::Session.new(:poltergeist)
    else
      @session = Capybara::Session.new(:selenium)
    end
    @logged_in = false
  end


  #----------------------------------------------------------------#
  # Block wrapper for the API DSL- uses #instance_eval to run the 
  # given block within the context of this class.
  # In a perfect world, the class containing the DSL and the 
  # class executing Facebook elements would be two separate classes
  # but we haven't gotten there, yet.

   def facebook(&block)
    success = nil
    begin
      login
      success = instance_eval &block
      logout
    rescue FacebookError => e
      filename = screenshot
      puts "Error: #{e.message}. See above for more info" 
      success = false
    ensure
      @session.driver.quit
    end
    success
  end


#----------------------------------------------------------------#
#  API Methods
#----------------------------------------------------------------#

  def login(_nothingness=nil)
    if @logged_in
      return true
    end
    puts "Attempting to log in..."
    @session.visit "http://www.facebook.com"
    @session.fill_in('email', :with => @email)
    @session.fill_in('pass', :with => @password)
    @session.click_button 'Log In'
    @logged_in = true
    puts "   ...successfully logged in."
  end

#------------------------------------------------------------------#

  def logout
    return unless @logged_in
    puts "Attempting to log out..."
    begin
      @session.visit "http://www.facebook.com"
      @session.click_on('pageLoginAnchor')
      @session.within('#logout_form') do
         @session.click_button "Log Out"
      end
    rescue
      raise FacebookError, "Issues clicking the logout button."
    end
    begin
      @session.find("body.UIPage_LoggedOut")
      @logged_in = false
      puts "   ...logged out."

    rescue Capybara::ElementNotFound
      @logged_in = true
      puts "   ...could not log out."
    end
  end


#------------------------------------------------------------------#

  def join_event(data)
    facebook_id = data["id"]
    login
    begin
      puts "Finding an event..."

      @session.visit "https://www.facebook.com/events/upcoming"
      @session.within("#pagelet_suggested_events .fbEventsSuggestionItem", match: :first) do
        begin
          @session.click_link_or_button("Join")
        rescue
          raise FacebookError, "Cannot find a Join button."
        end
        puts "   ... found!"
        puts "Inviting friends..."
        @session.click_link_or_button("Invite Friends")
      end
      @session.within(".profileBrowserDialog") do
        searchbox = @session.find(".inputtext")
        searchbox.set data["friend_name"]
        begin
          if @session.has_css?(".listSection")
            @session.within(".listSection") do
              if @session.has_text?(data["friend_name"])
                begin
                  el = @session.find(".checkbox", :match => :first)
                  el.click
                  puts "checked!"
                  screenshot("friend_shot_3")

                rescue
                  raise FacebookError, "Checking the box isn't working"
                end
              else
               raise FacebookError, "Cannot find that specific friend's name"
             end
            end
          end
        rescue
          raise FacebookError, "Cannot find that friend in a list"
        end
      end
      begin
        @session.within(".uiOverlayFooterButtons") do
          @session.find(".layerConfirm").trigger("click")
        end
      rescue
        raise FacebookError, "Problem clicking send"
      end
    rescue => e
      raise FacebookError, "Generic event joining error: " + e.message
    end
    val = @session.has_text? "Your friend will be invited"
    if val
      puts "   ....invited!"
      return true
    else
      raise FacebookError, "Did not get confirmation of invitation"
    end
    return false
  end

#------------------------------------------------------------------#

  def block(data)
    facebook_id = data["id"]
    login
    open_friend_menu(facebook_id)
    @session.click_on("Block")
    @session.click_on("Confirm")
  end

#------------------------------------------------------------------#

  def unblock(data)
    facebook_id = data["id"]

    login
    @session.visit "http://www.facebook.com"
    @session.within('#navPrivacy') do
      @session.find("a").click
      @session.click_link_or_button("How do I stop someone from bothering me?")
      @session.click_link_or_button("View All Blocked Users")
    end
    @session.within('._t .uiList') do
      @session.all("li").each do |li|
        linktext = "https://www.facebook.com/#{facebook_id}"
        puts linktext
        if li.has_link?("", :href=>linktext)
          li.click_link_or_button("Unblock")
        else
          raise FacebookError, "didn't find #{facebook_id} when trying to unblock"
        end
      end
    end
    @session.click_on("Confirm")
  end


#------------------------------------------------------------------#

  def friend(data)
    facebook_id = data["id"]

    login
    @session.visit "http://www.facebook.com/#{facebook_id}"
    begin 
      @session.within('.FriendButton', match: :first) do
        if @session.has_text? "Friends"
          puts "already friends!"
          return false
        elsif @session.has_button? "Add Friend"
          @session.click_link_or_button("Add Friend")
          if @session.has_no_button? "Friend Request Sent"
            raise FacebookError, "Somehow your friend request for #{facebook_id} failed."
          else 
            return true
          end
        else
          raise FacebookError, "You screwed up trying to find a friend request button."
        end
      end
    rescue Capybara::ElementNotFound
      raise FacebookError "Cannot friend #{facebook_id}."
    end
  end

  
#------------------------------------------------------------------#

  def unfriend(data)
    facebook_id = data["id"]

    login
    @session.visit "http://www.facebook.com/#{facebook_id}"
    @session.within('.FriendButton', match: :first) do
      if @session.has_no_text? "Friends"
        raise FacebookError, "You can't unfriend someone who isn't your friend"
      else
        @session.click_link_or_button("Friends")
      end
    end
    @session.click_link_or_button("Unfriend")
    return true
  end

#------------------------------------------------------------------#

  def post(data)
    facebook_id = data["id"]
    message = data["message"]
    raise FacebookError, "No Message!" unless message
    login
    puts "Attempting to post '#{message}'..."

    @session.visit "http://www.facebook.com/#{facebook_id}"
    begin
      @session.within('#u_0_1d') do
        textarea = @session.find_field("Write something...")
        textarea.click
        textarea.native.send_keys(message)
      end
    rescue
      raise FacebookError, "Problems finding the text field."
    end
    begin
      buttn=@session.find("._ohf button._4jy0")
      buttn.click
    rescue
      raise FacebookError, "can't find button"
    end
    begin
      @session.within(".fbTimelineUnit.lastCapsule", :wait => 30) do
        if @session.has_no_text? message
         raise FacebookError, "Somehow your post failed."
        end
      end
    rescue
      if @session.find("._1yv").has_text? "This status update appears to be blank."
        raise FacebookError, "Somehow, your status was blank."
      else
         raise FacebookError, "Couldn't find the lastCapsule."
      end
    end
    puts "   ... posted."
    return true
  end

#------------------------------------------------------------------#

  def poke(data)
    facebook_id = data["id"]

    puts "Trying to poke #{facebook_id}..."
    open_friend_menu(facebook_id)
    begin
      @session.click_on("Poke")
    rescue
      raise FacebookError, "You cannot poke this person."
    end
    if @session.has_text?("You poked", :wait =>10)
      puts "   ...poked #{facebook_id}."
      return true
    elsif @session.has_text?("has not responded to your last poke.", :wait =>10)
      puts "   ...you've already poked #{facebook_id}."
      return false
    else
      raise FacebookError, "Your Poke Failed."
    end
  end

  




  #----------------------------------------------------------------#
  # Helper methods
  #----------------------------------------------------------------#


  #----------------------------------------------------------------#
  # Take a screenshot, name it with the ticket number.
  def screenshot(filename=nil)
    fn = filename || @ticket || SecureRandom.uuid.to_s
    f = "screenshots/#{fn}.png"
    @session.save_screenshot(f)
    puts "Saved #{f}:"
    return f
  end

  #----------------------------------------------------------------#
  def open_friend_menu(facebook_id)
    begin
      @session.visit "http://www.facebook.com/#{facebook_id}"
      @session.has_css?(".fbTimelineUn")
      @session.within("#pagelet_timeline_profile_actions .actionsContents") do
        btn = @session.find("button")
        if btn
           btn.click
        else
          raise FacebookError, "I cannot find the first button"
        end
      end
      @session.within("#globalContainer") do
        unless @session.has_text?("See Friendship")
          raise FacebookError, "I cannot see the dropdown" 
        end
      end
    rescue
      raise FacebookError, "Could not find the friend menu."
    end
  end

end