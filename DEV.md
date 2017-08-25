## Development Environment

You may want to watch [Your First Slack Bot Service video](http://code.dblock.org/2016/03/11/your-first-slack-bot-service-video.html) first.

### Prerequisites

Ensure that you can build the project and run tests. You will need these.

- [MongoDB](https://docs.mongodb.com/manual/installation/)
- [Firefox](https://www.mozilla.org/firefox/new/)
- [Geckodriver](https://github.com/mozilla/geckodriver), download, `tar vfxz` and move to `/usr/local/bin`
- Ruby 2.3.1

```
bundle install
bundle exec rake
```

### Slack Team

Create a Slack team [here](https://slack.com/create).

### Slack App

Create a test app [here](https://api.slack.com/apps). This gives you a client ID and a client secret.

Under _Features/OAuth & Permissions_, configure the redirect URL to `http://localhost:5000`.

Add the following Permission Scope.

* Add a bot user with the username @bot.

### Slack Keys

Create a `.env` file.

```
SLACK_CLIENT_ID=slack_client_id
SLACK_CLIENT_SECRET=slack_client_secret
```

### Stripe Keys

If you want to test paid features or payment-related functions you need a [Stripe](https://www.stripe.com) account and test keys. Add to `.env` file.

```
STRIPE_API_PUBLISHABLE_KEY=pk_test_key
STRIPE_API_KEY=sk_test_key
```

### Start the Bot

```
$ foreman start

08:54:07 web.1  | started with pid 32503
08:54:08 web.1  | I, [2017-08-04T08:54:08.138999 #32503]  INFO -- : listening on addr=0.0.0.0:5000 fd=11
```

Navigate to [localhost:5000](http://localhost:5000).

### Interactive Buttons

To test interactive buttons locally you need [ngrok](https://ngrok.com) to tunnel to `localhost:5000`.

```
ngrok http 5000
```

This will give you a forwarding HTTPs URL, such as `https://a740cdc9.ngrok.io -> localhost:5000`.

Enter `https://a740cdc9.ngrok.io/api/slack/action/` in the Slack `Interactive Messages` configuration section of your app under `Request Url`.

### Google Calendar Integration

* Create a new project on https://console.developers.google.com
* Click `Enable APIs and Services`
* Look for `Google Calendar API`, choose `Enable`
* Choose `Add Credentials`, accessing `User Data` via `Google Calendar API` via `Web Browser (Javascript)`
* Answer remaining questions and `Create a Client ID`
* Set `GOOGLE_API_CLIENT_ID`



