require 'discordrb'
require './lib/spoilerbot.rb'
require 'sequel'

# Check for required env. variables
["DISCORD_BOT_ID", "DISCORD_BOT_TOKEN"].each do |var|
    unless ENV[var]
        puts "#{var}: variable not specified, exiting."
        return
    end
end

puts "Will try connecting to the DB specified in MAMI_DB" if ENV['MAMI_DB']
$MamiDB = Sequel.connect(ENV['MAMI_DB'] || 'sqlite://spoilerbot_configs.db') 

unless $MamiDB.table_exists?(:configs)
    $MamiDB.create_table :configs do
        primary_key :id, unique: true, null: false
        Integer :server_id, unique: true, null: false
        String :emoji, null: false
        Float :delay, null: false
        Integer :offset, null: false
    end
    puts "Table created."
end

# Create the bot
bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_BOT_TOKEN'], client_id: ENV['DISCORD_BOT_ID'], prefix: "!"
bot.include! MamiTheSpoilerBot

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

bot.run
