require 'discordrb'
require './lib/mami.rb'
require 'sequel'

# Check for required env. variables
["MAMI_DISCORD_BOT_ID", "MAMI_DISCORD_BOT_TOKEN"].each do |var_name|
  unless ENV[var_name]
    puts "[ERR] #{var_name}: variable not specified, exiting."
    exit
  end
end

if ENV["MAMI_DELETION_DELAY"]
  puts "[INFO] The bot will wait for #{ENV["MAMI_DELETION_DELAY"]} before deleting a message."
end

begin
  $MamiDB = if ENV['MAMI_DB']
    puts "[DB] Trying to connect to the DB specified in MAMI_DB"
    Sequel.connect(ENV['MAMI_DB'])
  elsif ENV['MAMI_SQLITE3_DB_CUSTOM_FILE']
    puts "[DB] Trying to connect to a SQLite3 database file specified in MAMI_SQLITE3_DB_CUSTOM_FILE"
    Sequel.sqlite(ENV['MAMI_SQLITE3_DB_CUSTOM_FILE'])
  else
    puts "[DB] Connecting to standard SQLite3 DB."
    Sequel.sqlite('mami_server_configs.sqlite')
  end
rescue Sequel::DatabaseConnectionError => e
  puts "[ERR] Connection to DB failed, exiting."
  exit
end

unless $MamiDB.table_exists?(:mami_server_configs)
  $MamiDB.create_table :mami_server_configs do
    primary_key :id, unique: true, null: false
    Integer :server_id, unique: true, null: false
    String :emoji, null: false
    Float :delay, null: false
    Integer :offset, null: false
  end
  puts '[DB] Table "mami_server_configs" created.'
end

puts "[INFO] The bot will use '#{ENV["MAMI_PREFIX"]}' as the prefix." if ENV["MAMI_PREFIX"]

# Create the bot
bot = Discordrb::Commands::CommandBot.new(
  token: ENV['MAMI_DISCORD_BOT_TOKEN'], 
  client_id: ENV['MAMI_DISCORD_BOT_ID'], 
  prefix: ENV["MAMI_PREFIX"] || "!"
)
bot.include! MamiTheSpoilerBot

puts "[INFO] This bot's invite URL is #{bot.invite_url(permission_bits: 8192)}."
puts '[INFO] Click on it to invite it to your server.'

bot.run
