require 'discordrb'
require './lib/spoilerbot.rb'

# Create the bot
bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_BOT_TOKEN'], client_id: ENV['DISCORD_BOT_ID'], prefix: "!"
bot.include! MamiTheSpoilerBot

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

bot.run
