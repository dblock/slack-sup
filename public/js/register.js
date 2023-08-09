$(document).ready(function() {
    // Slack OAuth
    var code = $.url('?code')
    var version = $.url('?version')
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
    } else if (version != '1') {
        // redirect to S'Up 2
        window.location.href = "https://sup2.playplay.io";
    }
});