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
    puts '-----'
    puts '0', @original_text
    text = CGI.unescapeHTML(@original_text)
    puts '1', text
    text = replace(text)
    puts '2', text
    translated_text = Translator.google_translate.translate(text, to: 'en', model: 'nmt').text.to_s
    puts '3', translated_text
    translated_text = restore(translated_text)
    puts '4', translated_text
    translated_text.gsub!(/><@/, '> <@')
    translated_text.gsub!(/><!/, '> <!')
    puts '5', translated_text
    puts '-----'
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
      index = @emojis.length
      @emojis << $1
      "<e#{index}>"
    }
    ## Replace mentioned name
    @mentions = []
    text.gsub!(/<@([\-\w]+)>/) {
      index = @mentions.length
      @mentions << $1
      "<m#{index}>"
    }
    ## Annoucement like <!channel>
    @announcements = []
    text.gsub!(/<\!([\-\w]+)>/) {
      index = @announcements.length
      @announcements << $1
      "<a#{index}>"
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
      ])
  end

  match /\p{Hiragana}|\p{Katakana}|[一-龠々]/ do |client, data, match|
    text = data.text
    username = Slack::Web::Client.new.users_info(user: data.user)[:user][:name]
    if data['subtype'] && data['subtype'] == 'file_share'
      ## File
      title = data[:file][:title]
      reply_text = "uploaded: #{Translator.translate(title)}"
      if data[:file][:initial_comment]
        comment = data[:file][:initial_comment][:comment]
        reply_text += "\n#{Translator.translate(comment)}"
      end
      reply(client, data, username, reply_text)
    else
      ## Text
      reply(client, data, username, Translator.translate(text))
    end
  end
end

TranslationBot.run

