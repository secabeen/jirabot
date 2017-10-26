# LSCGSlackBot
A Slack bot that watches any channel it's invited to for mentions of LSCG issues. If it sees one, it responds with a message consisting of the link to our internal ticketing systems.

## Setup
You'll need to configure a bot on Slack (fixme: Add setup link) and get your API token. Once you have that, set a new environmental variable `SLACK_API_TOKEN`.

For local development, you can do this with a `.env` file, which we've helpfully left out of this repo.

    # ENV Sample
    SLACK_API_TOKEN=yourtokengoeshere

For production use with foreman, put additional directives in .env, and have foreman create an init script.

## Running Locally

    foreman start

This will open your connection to the Slack API, and your bot will be online. You can connect to it and chat with it directly (it'll behave the same way).
