# Translation Bot

A Slack bot to translate Japanese messages into English by using Google Cloud Translation API

![Screenshot](https://i.gyazo.com/6af2609ced8b1788deb75ef4f5d5c088.png)

## Requirements

- Enable [Google Cloud Translation API](https://cloud.google.com/translate/) and get TRANSLATE_KEY
- [Add a Slack bot](https://slack.com/apps/build/custom-integration)
- Ruby (>= 2.0)

This bot is tested on Ubuntu 16.04.

## Install

    git clone git@github.com:takram-design-engineering/translation-bot.git
    cd translation-bot
    sudo gem install bundler
    bundle install

### Register as a systemd service (optional)

    sudo cp ~/translation-bot/systemd/translation-bot.service /etc/systemd/system/
    sudo systemctl enable translation-bot.service

Reload systemd after editing `/etc/systemd/system/translation-bot.service`.

    sudo systemctl daemon-reload

## Run the server

For development:

    TRANSLATE_KEY=xxxxx SLACK_API_TOKEN=xxxxx bundle exec ruby bot.rb

For systemd:

    sudo systemctl start translation-bot.service

## License

The MIT License  
Copyright (c) 2017 Takram
