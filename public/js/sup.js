var SlackSup = {};

$(document).ready(function() {

  SlackSup.message = function(text) {
    $('#messages').removeClass('has-error');
    $('#messages').fadeOut('slow', function() {
      $('#messages').fadeIn('slow').html(text)
    });
  };

  SlackSup.register = function(text) {
    $('.navbar').fadeOut('slow');
    $('header').fadeOut('slow');
    $('section').fadeOut('slow');
    $('#register').show();
  };

  SlackSup.error = function(xhr) {
    var message;
    if (xhr.responseText) {
      var rc = JSON.parse(xhr.responseText);
      if (rc && rc.error) {
        message = rc.error;
      } else if (rc && rc.message) {
        message = rc.message;
        if (message == 'invalid_code') {
          message = 'The code returned from the OAuth workflow was invalid.'
        } else if (message == 'code_already_used') {
          message = 'The code returned from the OAuth workflow has already been used.'
        }
      }
    }

    SlackSup.message(message || xhr.statusText || xhr.responseText || 'Unexpected Error');
    $('#messages').addClass('has-error');
  };
});
