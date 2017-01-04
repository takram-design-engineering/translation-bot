#!/usr/bin/env ruby

require 'slack-ruby-bot'
require 'google/cloud/translate'
require 'cgi'
require 'pp'

class TranslationBot < SlackRubyBot::Bot
  @translate = Google::Cloud::Translate.new
  
  def self.translate(text)
    text = replace(text)
    translated_text = @translate.translate(text, to: 'en', model: 'nmt').text.to_s
    translated_text = restore(translated_text)
    translated_text = CGI.unescapeHTML(translated_text)
    translated_text
  end
  
  def self.replace(text)
    ## Replace emoji
    text.gsub! /:([\+\w]+):/, '[[[\1]]]'
    ## Replace mentioned name
    text.gsub! /<@([\-\w]+)>/, '{{{\1}}}'
    text.gsub! /<\!([\-\w]+)>/, '(((\1)))'
    text
  end
  
  def self.restore(translated_text)
    ## Restore emoji
    translated_text.gsub! /\[\[\[([\+\w]+)\]\]\]/, ':\1:'
    ## Restore mentioned name
    translated_text.gsub! /\{\{\{([\-\w]+)\}\}\}/, '<@\1>'
    translated_text.gsub!(/\(\(\(([\-\w]+)\)\)\)/) {|matched| "<!#{$1.downcase}>"}
    translated_text
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
      ])
  end

  match /\p{Hiragana}|\p{Katakana}|[一-龠々]/ do |client, data, match|
    text = data.text
    username = Slack::Web::Client.new.users_info(user: data.user)[:user][:name]
    if data['subtype'] && data['subtype'] == 'file_share'
      title = data[:file][:title]
      reply_text = "uploaded: #{translate(title)}"
      if data[:file][:initial_comment]
        comment = data[:file][:initial_comment][:comment]
        reply_text += "\n#{translate(comment)}"
      end
      reply(client, data, username, reply_text)
    else
      reply(client, data, username, translate(text))
    end
  end
end

TranslationBot.run

