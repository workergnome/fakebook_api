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
  promise.done (e) ->
    data = JSON.parse(e)
    showStatus data

#----------------------------------------------#

showStatus = (ticketData) ->
  ticketData.error = ticketData.status == -1
  ticketData.processing = ticketData.status == 0
  ticketData.complete = ticketData.status == 1
  html = HandlebarsTemplates.status(ticketData)
  line = $("##{ticketData.ticket}")
  if line.length
    line.replaceWith(html)
  else
    line = $("#statuses").append(html)  

#----------------------------------------------#

checkFields = (e) ->
  valid = true
  
  if $('#fb_action').val() == "Post"
    $('#message_group').removeClass("hidden")
    $("#message").addClass("required")
  else
    $('#message_group').addClass("hidden")
    $("#message").val('').removeClass("required")

  $('.required').each () ->
    if $(this).val().length == 0 
      valid = false 

  if valid then $('#do_fb').removeClass("disabled")  else $('#do_fb').addClass("disabled")
  console.log "valid: ", valid


#----------------------------------------------#

updateStatus = () ->
  $('.status_row').each () ->
    $item = $(this)
    if $item.data("status") == 0
      promise = $.getJSON("/status/#{$item.attr('id')}")
      promise.done(showStatus)
  setTimeout(updateStatus,5000)

#----------------------------------------------#

$ ->
  checkFields()
  $(document).on "click", "#do_fb", submitToFacebook
  $(document).on "keyup", ".required", checkFields
  $('#fb_action').on "change", checkFields
  updateStatus()