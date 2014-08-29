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
  status = ticketData.status
  id = ticketData.ticket
  line = $("##{id}")
  text = "#{id}: #{if status == 0 then 'processing' else 'complete'}"
  if line.length
    line.data("status",status).text(text)
  else
    html = "<div class='row status' id='#{id}' data-status='#{status}'><a href='/pretty_status/#{id}'>#{text}</a></div>"
    line = $("#statuses").append(html)  

  if status == 0
    line.addClass("bg-primary")
  else if status == 1
    line.removeClass("bg-primary").addClass("bg-success")
  else if status == -1
    line.removeClass("bg-primary").addClass("bg-danger")

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
  $('.status').each () ->
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