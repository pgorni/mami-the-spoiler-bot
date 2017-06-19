require 'rot13'
require 'discordrb'

class SpoilerBotEncoder

	def self.enc_standard(text, offset=13)
		standard_regex = /\[spoiler\](.+?)\[\/spoiler\]/
		return text.gsub(standard_regex) {|spoiler_with_tags| "**" + Rot13.rotate(spoiler_with_tags.match(standard_regex)[1], offset) + "**"} 
	end

	def self.enc_modern(text, offset=13)
		modern_regex = /\[(?<spoiler_description>.+?)\]:\[(?<spoiler_text>.+?)\]/
		return text.gsub(modern_regex) {|spoiler| "*#{spoiler.match(modern_regex)["spoiler_description"]}:* **#{Rot13.rotate(spoiler.match(modern_regex)["spoiler_text"], offset)}**"}
	end

	def self.decode(text, offset=-13)
		return text.gsub(/\*\*(?<caesar>[\p{Word}\s]+)\*\*/) {|spoiler_with_tags| Rot13.rotate(spoiler_with_tags, offset)}
	end

end

module MamiTheSpoilerBot
	extend Discordrb::EventContainer
	extend Discordrb::Commands::CommandContainer

	standard_regex = /\[spoiler\](.+?)\[\/spoiler\]/
	modern_regex = /\[(?<spoiler_description>.+?)\]:\[(?<spoiler_text>.+?)\]/

	reaction_limiter = Discordrb::Commands::SimpleRateLimiter.new
	reaction_limiter.bucket :decoding, delay: 5 

	# Server config
	@server_config = {}

	# When the bot is ready and connected to Discord, create default config for all the servers the bot is on
	ready do |event|
		event.bot.servers.keys.each do |server_key|
			@server_config[server_key] = {"emoji": "❓", "delay": 4, "offset": 13}
		end

		event.bot.name = "Mami the Spoiler Bot"
		event.bot.game = "on #{@server_config.count} servers"
	end

	# When the bot joins a server, create default config for it
	server_create do |event|
  		@server_config[event.server.id] = {"emoji": "❓", "delay": 4, "offset": 13}
  		event.bot.game = "on #{@server_config.count} servers"
	end

	# When the bot leaves a server, remove its config
	server_delete do |event|
  		@server_config.delete(event.server.id)
  		event.bot.game = "on #{@server_config.count} servers"
	end

	message(contains: standard_regex) do |event|
		# Get the values for the server from the config
		emoji, delay, offset = @server_config[event.server.id].values

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
		emoji, delay, offset = @server_config[event.server.id].values

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
		if event.emoji.name == @server_config[event.channel.server.id][:emoji] and event.user.current_bot? == false
			timeout = reaction_limiter.rate_limited?(:decoding, event.channel)
			timeout == false ? event.user.pm(SpoilerBotEncoder.decode(event.message.text)) : event.user.pm("Calm down for #{timeout.ceil} more seconds.")
		end
	end

	command(:set_delay, required_permissions: [:administrator], permission_message: false) do |event, delay|
		@server_config[event.server.id][:delay] = delay.to_f
		event.respond("#{event.author.mention}: Spoiler delay set to #{@server_config[event.server.id][:delay]}!")
	end

	command(:set_emoji, required_permissions: [:administrator], permission_message: false) do |event, emoji|
		@server_config[event.server.id][:emoji] = emoji
		event.respond("#{event.author.mention}: Emoji set to #{@server_config[event.server.id][:emoji]}!")
	end

	command(:set_offset, required_permissions: [:administrator], permission_message: false) do |event, offset|
		@server_config[event.server.id][:offset] = offset.to_i
		event.respond("#{event.author.mention}: ROT13 offset to #{@server_config[event.server.id][:offset]}!")
	end

	command(:display_config, required_permissions: [:administrator], permission_message: false) do |event|
		emoji, delay, offset = @server_config[event.server.id].values
		event.respond("#{event.author.mention}: emoji: #{emoji}, delay: #{delay}, ROT13 offset: #{offset}, servers: #{@server_config.count}")
	end

end