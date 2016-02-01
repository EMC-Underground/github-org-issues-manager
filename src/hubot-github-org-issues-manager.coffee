# Description
#   A script that allows for hubot interact with a github org's repo issues
#
# Configuration:
#   HUBOT_GITHUB_USER_ACCESS_TOKEN - The bot's user token
#   HUBOT_GITHUB_ORG - The GitHub orginization the bot belongs to
#
# Commands:
#   hubot list repos - lists github repos that are available for issue submission
#
# Notes:
#   It is highly recommended that you create a seperate user on your org for the bot. This will allow better access control.
#
# Author:
#   JP Quicksall <john.paul.quicksall@gmail.com>

http = require 'http'

module.exports = (robot) ->
  # List all known repos
  robot.respond /list(\sall)? repos/i, (msg) ->
    org = robot.brain.get('github_org') or process.env.HUBOT_GITHUB_ORG
    if org?
      msg.reply "Fetching repos..."
      payload = {}
      robot.http(url)
        .header('Header-type', 'header-var')
        .post(JSON.stringify(payload)) (err, res, body) ->
          if err
            robot.logger.info "Encountered an error: #{err}"
            msg.send "Encountered an error: #{err}"
            return
          else
            msg.send "#{JSON.stringify(body, null, 2)}"
