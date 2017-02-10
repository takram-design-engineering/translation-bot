#!/usr/bin/env ruby

require 'slack-ruby-bot'
require 'google/cloud/translate'
require 'cgi'
require 'pp'

module LanguageType
  English = 1,
  Japanese = 2
end

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
      language_type = get_language_type line
      if language_type
        translate_line(line, language_type)
      else
        line
      end
    }.join("\n")
  end

  def translate_line(text, language_type)
    puts text
    text = replace(text)
    puts text

    translate_type = language_type === LanguageType::Japanese ? { "from" => "ja", "to" => "en" } : { "from" => "en", "to" => "ja" }
    translated_text = Translator.google_translate.translate(text, from: translate_type["from"], to: translate_type["to"], model: 'nmt').text.to_s

    puts translated_text
    translated_text = restore(translated_text)
    translated_text.gsub!(/><@/, '> <@')
    translated_text.gsub!(/><!/, '> <!')
    translated_text.gsub!(/><#/, '> <#')
    translated_text = CGI.unescapeHTML(translated_text)
    puts translated_text
    translated_text
  end

  def self.google_translate
    @@translate_ ||= Google::Cloud::Translate.new
  end

  def get_language_type(text)
    language_type = nil
    is_japanese = text.match(/\p{Hiragana}|\p{Katakana}|[一-龠々]/)
    is_english = text.match(/[a-zA-Z]+/)

    if is_japanese
      language_type = LanguageType::Japanese
    elsif is_english
      language_type = LanguageType::English
    end
    language_type
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

  def self.receive_message(client, data, match)
    username = Slack::Web::Client.new.users_info(user: data.user)[:user][:name]
    if data['subtype'] && data['subtype'] == 'file_share'
      reply(client, data, username, translate_uploaded_message(data))
    else
      reply(client, data, username, Translator.translate(data.text))
    end
  end

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
    receive_message(client, data, match)
  end

  match /[a-zA-Z]+/ do |client, data, match|
    receive_message(client, data, match)
  end

end

TranslationBot.run

