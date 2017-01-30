#!/usr/bin/env ruby

require 'slack-ruby-bot'
require 'google/cloud/translate'
require 'cgi'
require 'pp'

class Translator
  def self.translate(text)
    Translator.new(text).translate
  end

  def initialize(text)
    @original_text = text
  end

  def translate
    lines = @original_text.split("\n")
    lines.map {|line|
      if line.match(/\p{Hiragana}|\p{Katakana}|[一-龠々]/)
        translate_line(line)
      else
        line
      end
    }.join("\n")
  end

  def translate_line(text)
    puts text
    text = replace(text)
    puts text
    translated_text = Translator.google_translate.translate(text, from: 'ja', to: 'en', model: 'nmt').text.to_s
    puts translated_text
    translated_text = restore(translated_text)
    translated_text.gsub!(/><@/, '> <@')
    translated_text.gsub!(/><!/, '> <!')
    translated_text = CGI.unescapeHTML(translated_text)
    puts translated_text
    translated_text
  end

  def self.google_translate
    @@translate_ ||= Google::Cloud::Translate.new
  end

  private

  def replace(text)
    ## Replace emoji
    @emojis = []
    text.gsub!(/:([\+\-\w]+):/) {
      @emojis << $1
      "<e#{ @emojis.length - 1 }>"
    }

    ## Replace mentioned name
    @mentions = []
    text.gsub!(/<@([\w\d\-\.\_\|]+)>/) {
      @mentions << $1
      "<m#{ @mentions.length - 1 }>"
    }

    ## Annoucement like <!channel>
    @announcements = []
    text.gsub!(/<\!([\-\w]+)>/) {
      @announcements << $1
      "<a#{ @announcements.length - 1 }>"
    }

    ## Channel name
    @channels = []
    text.gsub!(/<#([\w\d\-\|]+)>/) {
      @channels << $1
      "<c#{ @channels.length - 1 }>"
    }
    text
  end

  def restore(text)
    ## Restore emoji
    text.gsub!(/<e(\d+)>/i) {|word|
      name = @emojis[$1.to_i]
      name ? ":#{name}:" : word
    }

    ## Restore mentioned name
    text.gsub!(/<m(\d+)>/i) {|word|
      name = @mentions[$1.to_i]
      name ? "<@#{name}>" : word
    }

    ## Restore annoucement
    text.gsub!(/<a(\d+)>/i) {|word|
      name = @announcements[$1.to_i]
      name ? "<!#{name}>" : word
    }

    ## Restore channel
    text.gsub!(/<c(\d+)>/i) {|word|
      name = @channels[$1.to_i]
      name ? "<\##{name}>" : word
    }
    text
  end
end

class TranslationBot < SlackRubyBot::Bot
  def self.reply(client, data, username, text)
    client.web_client.chat_postMessage(
      channel: data.channel,
      as_user: true,
      attachments: [
        {
          author_name: username,
          text: text
        }
      ]
    )
  end

  def self.translate_uploaded_message(data)
    title = data[:file][:title]
    reply_text = "uploaded: #{Translator.translate(title)}"
    if data[:file][:initial_comment]
      comment = data[:file][:initial_comment][:comment]
      reply_text += "\n\n\“ #{Translator.translate(comment)} \„"
    end
    reply_text
  end

  match /\p{Hiragana}|\p{Katakana}|[一-龠々]/ do |client, data, match|
    username = Slack::Web::Client.new.users_info(user: data.user)[:user][:name]
    if data['subtype'] && data['subtype'] == 'file_share'
      reply(client, data, username, translate_uploaded_message(data))
    else
      reply(client, data, username, Translator.translate(data.text))
    end
  end
end

TranslationBot.run

