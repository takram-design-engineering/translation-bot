require 'slack-ruby-bot'
require 'google/cloud'
require 'pp'

class TranslationBot < SlackRubyBot::Bot
  @gcloud    = Google::Cloud.new
  @translate = @gcloud.translate ENV['GOOGLE_API_KEY']
  
  def self.translate(text)
    puts '---'
    puts text
    text = replace(text)
    puts text
    translated_text = @translate.translate(text, to: 'en').text.to_s
    puts ''
    puts translated_text
    translated_text = restore(translated_text)
    puts translated_text
    puts '---'
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

  match /\p{Hiragana}|\p{Katakana}|[一-龠々]/ do |client, data, match|
    text = data.text
    username = Slack::Web::Client.new.users_info(user: data.user)[:user][:name]
    if data['subtype'] && data['subtype'] == 'file_share'
      title = data[:file][:title]
      reply_text = "*#{username}* uploaded: #{translate(title)}"
      if data[:file][:initial_comment]
        comment = data[:file][:initial_comment][:comment]
        reply_text += "\n#{translate(comment)}"
      end
      client.say(text: reply_text, channel: data.channel)
    else
      client.say(text: "*#{username}:* #{translate(text)}", channel: data.channel)
    end
  end
end

TranslationBot.run

