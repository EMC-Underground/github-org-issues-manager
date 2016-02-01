# Description
#   A script that allows for hubot interact with a github org's repo issues
#
# Configuration:
#   HUBOT_GITHUB_USER_ACCESS_TOKEN - The bot's user token
#
# Commands:
#   hubot hello - <what the respond trigger does>
#   orly - <what the hear trigger does>
#
# Notes:
#   It is highly recommended that you create a seperate user on your org for the bot. This will allow better access control.
#
# Author:
#   JP Quicksall <john.paul.quicksall@gmail.com>

module.exports = (robot) ->
  robot.respond /hello/, (res) ->
    res.reply "hello!"

  robot.hear /orly/, ->
    res.send "yarly"
