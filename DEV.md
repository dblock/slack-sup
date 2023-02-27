## Development Environment

### Prerequisites

Ensure that you can build the project and run tests. You will need these.

- [MongoDB](https://docs.mongodb.com/manual/installation/)
- [Firefox](https://www.mozilla.org/firefox/new/)
- [Geckodriver](https://github.com/mozilla/geckodriver)
- Ruby 2.7.7

```
bundle install
bundle exec rake
```

### Slack Team

Create a Slack team [here](https://slack.com/create).

### Slack App

Create a test app [here](https://api.slack.com/apps) from [the manifest](manifest.yml).

Use [ngrok](https://ngrok.com/) to tunnel to `localhost:5000`.

* Choose _Allow users to send Slash commands and messages from the messages tab_ under `App Home`.
* Use `https://....ngrok.io/api/slack/action` for _Interactivity and Shortcuts_.
* Use `https://....ngrok.io` for _Redirect Urls_ in _OAuth & Permissions_.
* Use `https://....ngrok.io/api/slack/event` in _Event Subscriptions_.

### Slack Keys

Create a `.env` file from [.env.sample](.env.sample) with at least the Slack keys.

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

### Google Calendar Integration

* Create a new project on https://console.developers.google.com
* Click `Enable APIs and Services`
* Look for `Google Calendar API`, choose `Enable`
* Choose `Add Credentials`, accessing `User Data` via `Google Calendar API` via `Web Browser (Javascript)`
* Answer remaining questions and `Create a Client ID`
* Set `GOOGLE_API_CLIENT_ID`
