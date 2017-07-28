# Mami the Spoiler Bot

### Intro
*Mami the Spoiler Bot* is a bot which replaces [spoilers](http://tvtropes.org/pmwiki/pmwiki.php/Main/Spoiler) with their [ROT13](https://en.wikipedia.org/wiki/ROT13) counterparts. This way no human should be able to read them (unless they are able to decipher ROT13 on-the-fly).

When the bot detects a message matching the syntax, the original message is quickly deleted. After that the bot reposts the original message with the spoiler text substituted and reacts to it with a specified emoji. When the emoji is clicked (and with that a new reaction added), the bot decodes the message and sends it using a private message.

This approach is one of the best ones due to the following reasons:
- it works on every machine the same way and doesn't require installing additional extensions (like CSS themes etc.)
- even if the bot dies in some nuclear attack, the spoilers still can be deciphered "by hand"
- it works on the mobile devices (requires a little tweaking, but it's possible)

### Mobile devices
The spoiler bot works on mobile devices. The mobile version of Discord, however, has some issues with caching. **Because of that fact, the default delay between deleting the original message and the "safe" message is set to 4 seconds.** This setting should work on most devices, but *it's probably a good idea* to test it on your server and increase the delay if such a need arises.
Also, if your internet connection's poor you *may* still see spoilers. This is also Discord's fault.

### Spoiler syntax
Multiple spoilers in one message are supported.
##### BBCode style
`[spoiler]your text goes here[/spoiler]`
##### Mami style
`[spoiler description]:[spoiler text]`

### Requirements
The bot requires the "manage messages" permission.

### Administrator commands
The following commands can be used only by users with the "administrator" permissions.
The default prefix is `!` and can be changed in the `bot.rb` file.

#### set_delay
Example: `!set_delay 3.5` will set the delay between deleting the original message and sending the spoilerless one to 3.5 seconds.

#### set_emoji
Example: `!set_emoji 🤔` will set the emoji used while decoding the spoiler to 🤔.
**It probably doesn't work with server-specific emoji.**

#### set_offset
Example: `!set_offset 2` will set the ROT13 offset to 2.

### User commands
The following commands are available to everyone.

#### mami_test
This command can be used to check if the bot is online and working well before attempting to spoil. It can also be used to check if the bot settings work for everyone.

### Is the bot publicly hosted somewhere?
You currently have to host it yourself, but I'll host one instance myself soon; probably with the next update.

### Known issues
- see the "Mobile devices" section
- if you change the decoding emoji, older messages with the old decoding emoji will stop being decoded - you probably can react to these messages with the new decoding emoji and it'll enable their decoding

### Installing
Install the dependencies listed below. Next just clone/download this repository and change your config in the `config.yaml` file.
The bot requires a Discord developer token. You can obtain one [here](https://discordapp.com/developers/applications/me).

### Dependencies
- Ruby (tested on 2.3.3)
- [discordrb](https://github.com/meew0/discordrb) ~> 3.2.1
- [rot13](https://github.com/jrobertson/rot13) ~> 0.1.3
- [Sequel](https://github.com/jeremyevans/sequel) ~> 4.47.0
- [sqlite3-ruby](https://github.com/sparklemotion/sqlite3-ruby) ~> 1.3.13

### Contributing
The project is under the GNU GPLv3 license. In order to contribute:

- fork the project
- change the code
- write spec tests (the project uses [RSpec](http://rspec.info)), make sure they pass
- issue pull requests

### To do
- increase spec tests coverage
- ~~make the per-server config persistent~~
- ~~make the diacritic signs work~~
- ~~add the status check command~~
- change the prefix
- add animated examples to the README.md file
- write help