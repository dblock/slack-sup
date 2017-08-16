$(document).ready(function() {
  // Slack OAuth
  var code = $.url('?code')
  if (code) {
    SlackSup.message('Working, please wait ...');
    $('#register').hide();
    $.ajax({
      type: "POST",
      url: "/api/teams",
      data: {
        code: code
      },
      success: function(data) {
        SlackSup.message('Team successfully registered!<br><br>DM <b>@sup</b> or create a <b>#channel</b> and invite <b>@sup</b> to it.');
      },
      error: SlackSup.error
    });
  }
});
