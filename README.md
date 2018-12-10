# Mami the Spoiler Bot

### Intro

*Mami the Spoiler Bot* is a bot which replaces [spoilers](http://tvtropes.org/pmwiki/pmwiki.php/Main/Spoiler) with their [ROT13](https://en.wikipedia.org/wiki/ROT13) counterparts. This way no human should be able to read them (unless they are able to decipher ROT13 on-the-fly).

When the bot detects a message matching the syntax, the original message is quickly deleted. After that the bot reposts the original message with the spoiler text substituted and reacts to it with a specified emoji. When the emoji is clicked (and with that a new reaction added), the bot decodes the message and sends it using a private message.

This approach is one of the best ones due to the following reasons:
- it works on every machine the same way and doesn't require installing additional extensions (like CSS themes etc.)
- even if the bot dies in some nuclear attack, the spoilers still can be deciphered "by hand"
- it works on the mobile devices (requires a little tweaking, but it's possible)

### Animated example

![mami_basic.gif](./doc/mami_basic.gif)

And some more with the extended syntax:

![mami_extended.gif](./doc/mami_extended.gif)

After clicking the buttons, you get some messages from the bot...

![mami_inc_msg.png](./doc/mami_inc_msg.png)

Seems they contain the deciphered messages!

![mami_dec.png](./doc/mami_dec.png)

### Mobile devices
The bot is somewhat compatible with mobile devices. The mobile version of Discord, however, has some issues with caching. **Because of that fact, the default delay between deleting the original message and the "safe" message is set to 5 seconds.** This setting should work on most devices, but *it's probably a good idea* to test it on your server and increase the delay if such a need arises. (I've seen some devices that lagged unless the delay was set to 6.5s...)
Also, if your internet connection's poor you *may* still see spoilers. This isn't the bot's fault, obviously.

There's also an option to set a delay *before* the original message is deleted. This may come in handy for those who want to host their own bots and know the delays between their servers and Discord. Setting this value may improve the bot's compatibility with mobiles. See more in the "Configuration" section.

### Spoiler syntax
Multiple spoilers in one message are supported.
##### BBCode style
`[spoiler]your text goes here[/spoiler]`
##### Mami style
`[spoiler description]:[spoiler text]`
##### Dollar sign style
`$$spoiler text$$`

### Requirements
The bot requires the "manage messages" permission.

### Administrator commands
The following commands can be used only by users with the "manage channels" permissions.
The default prefix is `!` and can be changed by specifying the `MAMI_PREFIX` environment variable.
All the examples below assume you're using the default `!` prefix.

You can also change the command itself by setting the `MAMI_CUSTOM_BOT_COMMAND_NAME` environment variable.
Example: the default way to call the bot would be `!mami <command>`. If you set the `MAMI_PREFIX` environment variable to `~` and `MAMI_CUSTOM_BOT_COMMAND_NAME` to `spoilers`, the bot will have to be called by typing `~spoilers <command>`.
All the examples below assume you're using the default `mami` command.

#### mami help
Actually display the bot's usage and most of what is written below.

#### mami set_delay
Example: `!mami set_delay 3.5` will set the delay between deleting the original message and sending the spoilerless one to 3.5 seconds.

#### mami set_emoji
Example: `!mami set_emoji 🤔` will set the emoji used while decoding the spoiler to 🤔.
**It probably doesn't work with server-specific emoji.**

#### mami set_offset
Example: `!mami set_offset 2` will set the ROT13 offset to 2.

#### mami display_config
Example: `!mami display_config` will reply with the current settings for this server.

### User commands
The following commands are available to everyone.
All the examples below assume you're using the default `!` prefix and the default `mami` command.

#### mami test
This command can be used to check if the bot is online and working well before attempting to spoil. It can also be used to check if the bot settings work for everyone.
The default rate limit is 5 seconds.

### Known issues
- see the "Mobile devices" section
- if you change the decoding emoji, older messages with the old decoding emoji will stop being decoded - you probably can react to these messages with the new decoding emoji and it'll enable their decoding

### Is the bot publicly hosted somewhere?
A public instance is running, [you can invite it here](https://discordapp.com/oauth2/authorize?&client_id=489418522812743681&permissions=8192&scope=bot). Note that it's running on limited resources, so your donations are more than welcome!


<a href="https://patreon.com/zanbots">
  <img src="https://c5.patreon.com/external/logo/become_a_patron_button@2x.png" height="50">
</a>

### Installing

Just clone/download this repository and set the following environment variables like this:

- `export MAMI_DISCORD_BOT_TOKEN=<token>`
- `export MAMI_DISCORD_BOT_ID=<bot_client_id>`

If you don't have a Discord bot token and ID, you can create them [here](https://discordapp.com/developers/applications/me).

Next, install the dependencies listed below (you can do so with `bundle install --without development` if you have Bundler installed on your system). 

The bot uses a database to store per-server configs. As of now, the bot supports MySQL2, SQLite3 and PostgreSQL databases.

There are 3 ways to store the configs:

#### 1. Use an external database system and connect to it with the `MAMI_DB` environment variable

You can specify the `MAMI_DB` variable (ex.: `export MAMI_DB=(...)` in order to connect to an external database. The bot will understand a database connection URI (more on this [here](https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-Using+the+Sequel.connect+method)).

**Note 1: The database has to exist first. The bot doesn't create databases on its own.**

**Note 2: If you have special symbols in your password, for example: '@', you have to URL-encode it. More on this can be found [here](https://github.com/jeremyevans/sequel/issues/1361). There are several URL-encoding tools available online.**


#### 2. Use a default SQLite3 database

If you don't specify a database URI, a default SQLite3 database file `mami_server_configs.sqlite` will be created in the bot's directory.
This is the easiest option if you just run the bot on your PC or a VPS without using Docker.

#### 3. Use a custom SQLite3 file path with the `MAMI_SQLITE3_DB_CUSTOM_FILE` variable

If you want to use a SQLite3 file as your database, but want to use Docker, you can use this variable to specify where the SQLite3 file will be created.
For example, if the dockerized bot has a volume link like `/docker-container-data/mami-the-spoiler-bot:/mami_db` specified and you set the `MAMI_SQLITE3_DB_CUSTOM_FILE` variable to `/mami_db/mami_db.sqlite`, the database will be created on the host machine instead of the Docker container.
**If you didn't do this, the database would be destroyed upon the container's restart.**

### Configuration

Now that the bot's installed, you can configure it with more environment variables.

#### Setting a deletion delay

You can set a timeout executed **before** deleting a message with a spoiler. This may raise compatibility with mobile devices.
You can do so by setting a `MAMI_DELETION_DELAY` environment variable.

#### Changing the prefix

You can change the prefix for the commands by setting the `MAMI_PREFIX` environment variable.

#### Changing the decoding and test command rate limit delays

You can change the decoding rate limit with the `MAMI_DECODING_RL` environment variable (the default rate limit is 5 seconds). Just remember that people like to spam the decoding button ;)

Similarly, the rate limit used in the `!mami test` command can be changed by setting the `MAMI_TEST_CMD_RL` variable.


#### Setting the bot as public

If you decide to host your own instance, you can set it as "public", which currently means that a link to invite it will appear in the `help` command.
You can set your instance as public by setting the `MAMI_IS_PUBLIC` environment variable to `true`.

### Docker support

The bot actually works with Docker. Here's a sample `docker-compose.yml` file:

```yaml
version: '2'
services:
  bot:
    image: pgorni/mami-the-spoiler-bot:latest
    volumes:
    # You *probably* want to set this if you used the MAMI_SQLITE3_DB_CUSTOM_FILE variable
    # or you used the default DB configuration. 
    - /some/path/on/host/mami-the-spoiler-bot:/.
    environment:
      - MAMI_DISCORD_BOT_ID=
      - MAMI_DISCORD_BOT_TOKEN=
      - MAMI_DELETION_DELAY=
      # - MAMI_DB=
      # - MAMI_SQLITE3_DB_CUSTOM_FILE= You don't need to set this if you use the MAMI_DB variable.
      - MAMI_PREFIX="!"
      - MAMI_CUSTOM_BOT_COMMAND_NAME="mami"
      - MAMI_DECODING_RL=5
      - MAMI_TEST_CMD_RL=5
      - MAMI_IS_PUBLIC="false"
    restart: unless-stopped
```
Edit it as you wish, save it as `docker-compose.yml` and then just run `docker-compose up`. 
(Note: you have to have Docker Compose installed on your system to do this.)

### Dependencies
- Ruby (tested on 2.3.3, 2.4.2 and 2.5.1)
- [discordrb](https://github.com/meew0/discordrb) ~> 3.2.1
- [rot13](https://github.com/jrobertson/rot13) ~> 0.1.3
- [Sequel](https://github.com/jeremyevans/sequel) ~> 5.1.0
- [sqlite3-ruby](https://github.com/sparklemotion/sqlite3-ruby) ~> 1.3.13
- [mysql2](https://github.com/brianmario/mysql2) ~> 0.4.10
- [pg](https://bitbucket.org/ged/ruby-pg/wiki/Home) ~> 0.18.4


### Contributing
The project is under the GNU GPLv3 license. In order to contribute:

- fork the project
- change the code
- write spec tests (the project uses [RSpec](http://rspec.info)), make sure they pass
- issue pull requests

### Donations
You can pay for the public instance's upkeep and the project's development on Patreon :revolving_hearts:
<a href="https://patreon.com/zanbots">
  <img src="https://c5.patreon.com/external/logo/become_a_patron_button@2x.png" height="50">
</a>

### To do
- increase spec tests coverage
- ~~dockerize~~
- ~~make the per-server config persistent~~
- ~~make the diacritic signs work~~
- ~~add the status check command~~
- ~~change the prefix~~
- ~~add animated examples to the README.md file~~
- ~~write help~~
