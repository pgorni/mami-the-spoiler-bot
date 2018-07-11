require 'discordrb'
require_relative 'spoiler_encoder.rb'

module MamiTheSpoilerBot
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  STANDARD_REGEX = /\[spoiler\](.+?)\[\/spoiler\]/
  MODERN_REGEX = /\[(?<spoiler_description>.+?)\]:\[(?<spoiler_text>.+?)\]/
  DOLLAR_SIGN_REGEX = /\$\$(.+?)\$\$/

  rate_limiter = Discordrb::Commands::SimpleRateLimiter.new
  # TODO: make this user-customizable
  rate_limiter.bucket :decoding, delay: 5 
  rate_limiter.bucket :test, delay: 5

  # Server config
  server_config = {}

  # When the bot is ready and connected to Discord, load all saved configs from the database
  ready do |event|    
    $MamiDB[:mami_server_configs].each do |server|
      _, server_id, emoji, delay, offset = server.values
      server_config[server_id] = {emoji: emoji, delay: delay, offset: offset}
    end

    puts "[DB] Settings from the DB loaded to memory."

    event.bot.name = "Mami the Spoiler Bot"
    event.bot.game = "on #{server_config.count} servers"
  end

  # When the bot joins a server, create default config for it and save it in the DB
  server_create do |event|
    default_server_config = {
      "emoji": "❓", 
      "delay": 4, 
      "offset": 13
    }
    server_config[event.server.id] = default_server_config
    $MamiDB[:mami_server_configs].insert( { server_id: event.server.id }.merge(default_server_config) )
    event.bot.game = "on #{server_config.count} servers"
  end

  # When the bot leaves a server, remove its config from memory and the DB
  server_delete do |event|
    server_config.delete(event.server.id)
    $MamiDB[:mami_server_configs].where(server_id: event.server.id).delete
    event.bot.game = "on #{server_config.count} servers"
  end

  # Reacting to spoilers
  # TODO: find a way to DRY code, maybe
  message(contains: STANDARD_REGEX) do |event|
    # Get the values for the server from the config
    emoji, delay, offset = server_config[event.server.id].values

    # Delete the message after waiting for a couple of miliseconds
    sleep(ENV["MAMI_DELETION_DELAY"].to_f) if ENV["MAMI_DELETION_DELAY"]
    event.message.delete

    # Duplicate original text
    safe_text = event.text.dup

    # Substitute the spoilers
    safe_text = SpoilerEncoder.enc_standard(safe_text, offset, STANDARD_REGEX)

    # Wait a while so that mobile devices don't lag behind
    sleep(delay)

    # Post the spoilerless message and react to that message
    event.respond(
      "CAUTION! This message may contain spoilers! \n#{event.author.mention} said: #{safe_text}"
    ).create_reaction(emoji)
  end

  message(contains: MODERN_REGEX) do |event|
    # Get the values for the server from the config
    emoji, delay, offset = server_config[event.server.id].values

    # Delete the message after waiting for a couple of miliseconds
    sleep(ENV["MAMI_DELETION_DELAY"].to_f) if ENV["MAMI_DELETION_DELAY"]
    event.message.delete

    # Duplicate original text
    safe_text = event.text.dup

    # Substitute the spoilers
    safe_text = SpoilerEncoder.enc_modern(safe_text, offset)

    # Wait a while so that mobile devices don't lag behind
    sleep(delay)

    # Post the spoilerless message and react to that message
    event.respond(
      "CAUTION! This message may contain spoilers!\n #{event.author.mention} said: #{safe_text}"
    ).create_reaction(emoji)
  end

  message(contains: DOLLAR_SIGN_REGEX) do |event|
    # Get the values for the server from the config
    emoji, delay, offset = server_config[event.server.id].values

    # Delete the message after waiting for a couple of miliseconds
    sleep(ENV["MAMI_DELETION_DELAY"].to_f) if ENV["MAMI_DELETION_DELAY"]
    event.message.delete

    # Duplicate original text
    safe_text = event.text.dup

    # Substitute the spoilers
    safe_text = SpoilerEncoder.enc_standard(safe_text, offset, DOLLAR_SIGN_REGEX)

    # Wait a while so that mobile devices don't lag behind
    sleep(delay)

    # Post the spoilerless message and react to that message
    event.respond(
      "CAUTION! This message may contain spoilers!\n #{event.author.mention} said: #{safe_text}"
    ).create_reaction(emoji)
  end

  reaction_add do |event|
    # Do not do anything if the reaction was added by the bot itself
    unless event.user.current_bot? 
      if event.emoji.name == server_config[event.channel.server.id][:emoji] and event.message.from_bot?
        timeout = rate_limiter.rate_limited?(:decoding, event.user)
        event.user.pm(
          unless timeout
            SpoilerEncoder.decode(event.message.text)
          else
            "Calm down for #{timeout.ceil} more #{timeout.ceil == 1 ? "second" : "seconds"}."
          end
        )
      end
    end
  end

  # Commands
  command(:mami) do |event, command, *args|
    server_id = event.server.id

    case command
    when /set_(delay|offset|emoji)/
      unless event.author.permission? :manage_channels
        # XXX does this suffice?
        event.respond("You aren't authorized to do that.")
        next 
      end

      setting = $1
      case setting
      when "delay"
        set_val = args.first.to_f
      when "offset"
        set_val = args.first.to_i
      when "emoji"
        set_val = args.first
      end

      server_config[server_id][setting.to_sym] = set_val
      $MamiDB[:mami_server_configs].where(server_id: server_id).update(Hash[setting, set_val])
      # This replies with the value from the memory so that there's no mistaking it was saved
      event.respond("#{event.author.mention}: #{setting.capitalize} set to #{server_config[event.server.id][setting.to_sym]}!")
    when "test"
      timeout = rate_limiter.rate_limited?(:test, event.user)

      unless timeout
        emoji, delay, _ = server_config[event.server.id].values
        if ENV["MAMI_DELETION_DELAY"]
          puts "[INFO] Will now sleep #{ENV["MAMI_DELETION_DELAY"]}s."
          sleep(ENV["MAMI_DELETION_DELAY"].to_f)
        end
        event.message.delete
        sleep(delay)
        event.respond("Mami is ready!").create_reaction(emoji)
      else
        event.respond("Everything is OK, but wait #{timeout.to_i} #{timeout.to_i == 1 ? "second" : "seconds"}.")
      end
    when "display_config"
      unless event.author.permission? :manage_channels
        # XXX does this suffice?
        event.respond("You aren't authorized to know that.")
        next 
      end
      emoji, delay, offset = server_config[server_id].values
      event.respond("#{event.author.mention}: emoji: #{emoji}, delay: #{delay}, ROT13 offset: #{offset}, servers: #{server_config.count}")
    end
  end

end