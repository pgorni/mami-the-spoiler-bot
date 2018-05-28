require 'rot13'
require 'discordrb'
require 'sequel'

$MamiDB = Sequel.connect('sqlite://spoilerbot_configs.db') 

unless $MamiDB.table_exists?(:configs)
    $MamiDB.create_table :configs do
        primary_key :id, unique: true, null: false
        Integer :server_id, unique: true, null: false
        String :emoji, null: false
        Float :delay, null: false
        Integer :offset, null: false
    end
    puts "Database created."
end




class SpoilerBotEncoder

    def self.enc_standard(text, offset=13)
        standard_regex = /\[spoiler\](.+?)\[\/spoiler\]/
        # We don't want any asterisks in the text, because that'd mess with the formatting
        text.gsub!("*", "")
        return text.gsub(standard_regex) {|spoiler_with_tags| "**" + Rot13.rotate(spoiler_with_tags.match(standard_regex)[1], offset) + "**"} 
    end

    def self.enc_modern(text, offset=13)
        modern_regex = /\[(?<spoiler_description>.+?)\]:\[(?<spoiler_text>.+?)\]/
        # We don't want any asterisks in the text, because that'd mess with the formatting
        text.gsub!("*", "")
        return text.gsub(modern_regex) {|spoiler| "*#{spoiler.match(modern_regex)["spoiler_description"]}:* **#{Rot13.rotate(spoiler.match(modern_regex)["spoiler_text"], offset)}**"}
    end

    def self.decode(text, offset=-13)
        regex = /\*\*(.+?)\*\*/
        return text.gsub(regex) {|spoiler_with_tags| Rot13.rotate(spoiler_with_tags, offset)}
    end

end

module MamiTheSpoilerBot
    extend Discordrb::EventContainer
    extend Discordrb::Commands::CommandContainer

    standard_regex = /\[spoiler\](.+?)\[\/spoiler\]/
    modern_regex = /\[(?<spoiler_description>.+?)\]:\[(?<spoiler_text>.+?)\]/

    rate_limiter = Discordrb::Commands::SimpleRateLimiter.new
    rate_limiter.bucket :decoding, delay: 5 
    rate_limiter.bucket :test, delay: 5


    # Server config
    server_config = {}

    # When the bot is ready and connected to Discord, load all saved configs from the database
    ready do |event|
        
        $MamiDB[:configs].each do |server|
            _, server_id, emoji, delay, offset = server.values
            server_config[server_id] = {emoji: emoji, delay: delay, offset: offset}
        end

        puts "Settings from the DB loaded to memory."

        event.bot.name = "Mami the Spoiler Bot"
        event.bot.game = "on #{server_config.count} servers"
    end

    # When the bot joins a server, create default config for it and save it in the DB
    server_create do |event|

        server_config[event.server.id] = {"emoji": "❓", "delay": 4, "offset": 13}

        $MamiDB[:configs].insert(server_id: event.server.id, emoji: "❓", delay: 4, offset: 13)

        event.bot.game = "on #{server_config.count} servers"
    end

    # When the bot leaves a server, remove its config from memory and the DB
    server_delete do |event|

        server_config.delete(event.server.id)

        $MamiDB[:configs].where(server_id: event.server.id).delete

        event.bot.game = "on #{server_config.count} servers"
    end

    message(contains: standard_regex) do |event|
        # Get the values for the server from the config
        emoji, delay, offset = server_config[event.server.id].values

        # Delete the message, fast!
        event.message.delete

        # Duplicate original text
        safe_text = event.text.dup

        # Substitute the spoilers
        safe_text = SpoilerBotEncoder.enc_standard(safe_text, offset)

        # Wait a while so that mobile devices don't lag behind
        sleep(delay)

        # Post the spoilerless message and react to that message
        event.respond("CAUTION! This message may contain spoilers!\n#{event.author.mention} said: #{safe_text}").create_reaction(emoji)
    end

    message(contains: modern_regex) do |event|
        # Get the values for the server from the config
        emoji, delay, offset = server_config[event.server.id].values

        # Delete the message, fast!
        event.message.delete

        # Duplicate original text
        safe_text = event.text.dup

        # Substitute the spoilers
        safe_text = SpoilerBotEncoder.enc_modern(safe_text, offset)

        # Wait a while so that mobile devices don't lag behind
        sleep(delay)

        # Post the spoilerless message and react to that message
        event.respond("CAUTION! This message may contain spoilers!\n#{event.author.mention} said: #{safe_text}").create_reaction(emoji)
    end

    reaction_add() do |event|
        # Do not do anything if the reaction was added by the bot itself
        unless event.user.current_bot? 
            if event.emoji.name == server_config[event.channel.server.id][:emoji] and event.message.from_bot?
                timeout = rate_limiter.rate_limited?(:decoding, event.user)
                event.user.pm(!timeout ? SpoilerBotEncoder.decode(event.message.text) : "Calm down for #{timeout.ceil} more #{timeout.ceil == 1 ? "second" : "seconds"}.")
            end
        end
    end

    command(:set_delay, required_permissions: [:administrator], permission_message: false) do |event, delay|
        server_config[event.server.id][:delay] = delay.to_f
        $MamiDB[:configs].where(server_id: event.server.id).update(delay: delay.to_f)
        event.respond("#{event.author.mention}: Spoiler delay set to #{server_config[event.server.id][:delay]}!")
    end

    command(:set_emoji, required_permissions: [:administrator], permission_message: false) do |event, emoji|
        server_config[event.server.id][:emoji] = emoji
        $MamiDB[:configs].where(server_id: event.server.id).update(emoji: emoji)
        event.respond("#{event.author.mention}: Emoji set to #{server_config[event.server.id][:emoji]}!")
    end

    command(:set_offset, required_permissions: [:administrator], permission_message: false) do |event, offset|
        server_config[event.server.id][:offset] = offset.to_i
        $MamiDB[:configs].where(server_id: event.server.id).update(offset: offset.to_i)
        event.respond("#{event.author.mention}: ROT13 offset to #{server_config[event.server.id][:offset]}!")
    end

    command(:display_config, required_permissions: [:administrator], permission_message: false) do |event|
        emoji, delay, offset = server_config[event.server.id].values
        event.respond("#{event.author.mention}: emoji: #{emoji}, delay: #{delay}, ROT13 offset: #{offset}, servers: #{server_config.count}")
    end

    command(:mami_test) do |event|

        timeout = rate_limiter.rate_limited?(:test, event.user)

        unless timeout
            emoji, delay, _ = server_config[event.server.id].values
            event.message.delete
            sleep(delay)
            event.respond("Mami is ready!").create_reaction(emoji)
        else
            event.respond("Everything is OK, but wait #{timeout.to_i} #{timeout.to_i == 1 ? "second" : "seconds"}.")
        end

    end


end