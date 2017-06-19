require 'discordrb'
require 'yaml'
require './spoilerbot.rb'

# Load the bot's config.
CONFIG = YAML.load_file('config.yaml')

# Create the bot
bot = Discordrb::Commands::CommandBot.new token: CONFIG['token'], client_id: CONFIG['id'], prefix: "!"

bot.include! MamiTheSpoilerBot

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

bot.run
