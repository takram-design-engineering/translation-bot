# Translation Bot

Slack bot translating Japanese into English

## Requirements

- [Google Cloud Translation API](https://cloud.google.com/translate/)
  - Enable the API and get your TRANSLATE_KEY
- Ruby (>= 2.0)

## Install

    git clone git@github.com:takram-design-engineering/translation-bot.git
    cd translation-bot
    sudo gem install bundler
    bundle install

### Systemd

    sudo cp ~/translation-bot/systemd/translation-bot.service /etc/systemd/system/
    sudo systemctl enable translation-bot.service

Reload systemd after editing `/etc/systemd/system/translation-bot.service`.

    sudo systemctl daemon-reload

## Run

Development:

    TRANSLATE_KEY=xxxxx SLACK_API_TOKEN=xxxxx bundle exec ruby bot.rb

Systemd:

    sudo systemctl start translation-bot.service

