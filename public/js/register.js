$(document).ready(function() {
  // Slack OAuth
  var code = $.url('?code')
  if (code) {
    SlackSup.register();
    SlackSup.message('Working, please wait ...');
    $.ajax({
      type: "POST",
      url: "/api/teams",
      data: {
        code: code
      },
      success: function(data) {
        SlackSup.message('Team successfully registered! Check your DMs.');
      },
      error: SlackSup.error
    });
  }
});
