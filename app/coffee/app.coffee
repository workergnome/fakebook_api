Handlebars.registerHelper "statusClass", (status) ->
  if status == 0
    "bg-primary"
  else if status == 1
    "bg-success"
  else if status == -1
    "bg-danger"
  else
    ""

#----------------------------------------------#
    
submitToFacebook = (e) ->
  e.preventDefault()
  obj =  $( "#api-test" ).serialize()
  url = "/#{$('#fb_action').val().toLowerCase()}"
  console.log url, obj
  promise = $.post url, obj 


#----------------------------------------------#

showStatus = (status) ->
  $("#statuses").html("")
  $("#completed").html("")
  for ticketData in status.pending
    ticketData.error = ticketData.status == -1
    ticketData.processing = ticketData.status == 0
    ticketData.complete = ticketData.status == 1
    ticketData.wait_time = "#{Math.round((Date.now()/1000 - ticketData.start_time))} seconds"
    ticketData.start_time = new Date(ticketData.start_time *1000).toString() 
    html = HandlebarsTemplates.status(ticketData)
    $("#statuses").append(html)  
  for ticketData in status.complete
    ticketData.error = ticketData.status == -1
    ticketData.processing = ticketData.status == 0
    ticketData.complete = ticketData.status == 1
    ticketData.wait_time = "#{Math.round(ticketData.end_time - ticketData.start_time)} seconds"
    ticketData.start_time = new Date(ticketData.start_time *1000).toString()
    html = HandlebarsTemplates.status(ticketData)
    $("#completed").append(html)  

#----------------------------------------------#

checkFields = (e) ->
  valid = true
  method = $('#fb_action').val()
  console.log("method")
  $("#friend").addClass("required")
  $('#friend_group').removeClass("hidden")
  $('#message_group').addClass("hidden")
  .removeClass("required")

  if method == "Post"
    $('#message_group').removeClass("hidden")
    $("#message").addClass("required")
  else
    $("#message").val('')
  
  if method == "Login"
    $("#friend").removeClass("required")
    $('#friend_group').addClass("hidden")

  $('.required').each () ->
    if $(this).val().length == 0 
      valid = false 

  if valid then $('#do_fb').removeClass("disabled")  else $('#do_fb').addClass("disabled")
  console.log "valid: ", valid


#----------------------------------------------#

updateStatus = () ->
  promise = $.getJSON("/status")
  promise.done(showStatus)
  setTimeout(updateStatus,900)

#----------------------------------------------#

$ ->
  checkFields()
  $(document).on "click", "#do_fb", submitToFacebook
  $(document).on "keyup", ".required", checkFields
  $('#fb_action').on "change", checkFields
  updateStatus()