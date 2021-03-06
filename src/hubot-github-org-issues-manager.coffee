# Description
#   A script that allows for hubot interact with a github org's repo issues
#
# Configuration:
#   HUBOT_GITHUB_USER_ACCESS_TOKEN - The bot's user token
#   HUBOT_GITHUB_ORG - The GitHub orginization the bot belongs to
#
# Commands:
#   hubot list repos - lists github repos that are available for issue submission
#   hubot list issues for <repo> - list all the issues for a given repo
#   hubot submit bug for <repo> as <issue> - submits a bug to a given repo; issue is a string
#   hubot submit enhancement for <repo> as <issue> - submits a bug to a given repo; issue is a string
#   hubot submit question for <repo> as <issue> - submits a bug to a given repo; issue is a string
#   hubot my github username is <username> - sets the github username for a user
#
# Notes:
#   It is highly recommended that you create a seperate user on your org for the bot. This will allow better access control.
#
# Author:
#   JP Quicksall <john.paul.quicksall@gmail.com>

http = require 'http'

base-url = "https://api.github.com/"

errors = {
  'github-org':"I have no Github Org to talk with...please specify one.",
  'github-access-token':"I do not have an access token for the specified org."
  'github-usernames': "I do not have any github usernames, please specify yours."
  'github-uesrname': "I do not have your username on file, please specify one."
}

module.exports = (robot) ->
  # Set a user's github account name
  robot.respond /my github username is (\w+)/i, (msg) ->
    usernames = robot.brain.get('github-names')
    if usernames = null
      usernames = {}
      robot.brain.set('github-names', usernames)
    username = msg.match[1]
    usernames[msg.envelope.user.name] = username
    msg.send "Your github username is now set to #{usernames[msg.envelope.user.name]}"

  # List all known repos
  robot.respond /list(\sall)? repos/i, (msg) ->

    # Get the org that the bot is assigned to
    org = robot.brain.get('github_org') or process.env.HUBOT_GITHUB_ORG
    token = robot.brain.get('github_user_token') or process.env.HUBOT_GITHUB_USER_ACCESS_TOKEN
    # Only run the code if the org exists
    if org?
      msg.reply "Fetching repos..."

      # Setup HTTP call
      robot.http(base-url + "/orgs/#{org}/repos")
        # Pass our auth token
        .header('Authorization', 'token #{token}')
        # Make the call
        .get() (err, res, body) ->
          if err
            robot.logger.info "Encountered an error: #{err}"
            msg.send "Encountered an error: #{err}"
            return
          else
            payload = {}
            for repo in body
              payload[repo['name']] = {"id": repo['id'],
                                        "full_name": repo['full_name'],
                                        "stargazer": repo['stargazers_count'],
                                        "watchers": repo['watchers_count'],
                                        "forks": repo['forks'],
                                        "primary_language": repo['language'],
                                        "issue_count": repo['open_issues_count']}
            msg.send "#{JSON.stringify(payload, null, 2)}"
    else
      msg.reply errors['github-org']


  # Get the issues for a specific repo
  robot.respond /list issues for (.+)/i, (msg) ->

    # Get the org that the bot is assigned to
    org = robot.brain.get('github_org') or process.env.HUBOT_GITHUB_ORG
    token = robot.brain.get('github_user_token') or process.env.HUBOT_GITHUB_USER_ACCESS_TOKEN
    repo_name = msg.match[1].lower()
    # Only run the code if the org exists
    if org?
      msg.reply "Fetching current issues for #{repo}..."

      # First fetch the repos
      robot.http(base-url + "/orgs/#{org}/repos")
        # Pass our auth token
        .header('Authorization', 'token #{token}')
        # Make the call to gather repos
        .get()) (err, res, body) ->
          if err # Stop if we couldn't get repos
            robot.logger.info "Encountered an error getting repos: #{err}"
            msg.send "Encountered an error getting repos: #{err}"
            return
          else # We got'em
            for repo in body # We want to search our list for the specified one
              if repo['name'].toLowerCase() is repo_name
                if repo['open_issues'] < 1 # Looks like author did good
                  msg.send "No open issues"
                  break
                else # Looks like there's issues. Send them to the user
                  robot.http(base-url + "/repos/#{org}/#{repo_name}/issues")
                    # Pass our auth token
                    .header('Authorization', 'token #{token}')
                    # Make the call
                    .get() (err2, res2, body2) ->
                      if err2
                        robot.logger.info "Encountered an error getting the repo's issues: #{err2}"
                        msg.send "Encountered an error getting the repo's issues: #{err2}"
                        return
                      else
                        payload = {}
                        for issue in body2
                          payload[issue['title']] = {"issue_number": issue['number'],
                                                      "submittee": issue['user']['login'],
                                                      "state": issue['state'],
                                                      "comment_count": issue['comments'],
                                                      "Description": issue['body']}
                        msg.send "#{JSON.stringify(payload, null, 2)}"
                        break
    else
      msg.reply errors['github-org']

  # Submit an issue for a repo
  robot.respond /submit(\sa|\san)? (bug|enhancement|question) for (.+) as (.+)/i, (msg) ->

    # Get the org that the bot is assigned to
    org = robot.brain.get('github_org') or process.env.HUBOT_GITHUB_ORG
    token = robot.brain.get('github_user_token') or process.env.HUBOT_GITHUB_USER_ACCESS_TOKEN
    issue_type = msg.match[2]
    repo_name = msg.match[3]
    issue_title = msg.match[4]
    # Only run the code if the org exists
    if org?
      # The submitee should have a github account
      # Get the github list
      usernames = robot.brain.get('github-names')
      # Continue if we got the list
      if usernames?
        # Verify a username exists for the user
        if usernames[msg.envelope.user.name]?
          msg.reply "Submitting issue..."
          payload = {"title": issue_title,
                      "body", "Courtesy of @#{usernames[msg.envelope.user.name]}",
                      "labels": [issue_type]}
          robot.http(bas-url + "/repos/#{org}/#{repo_name}/issues")
            # Pass our auth token
            .header('Authorization', 'token #{token}')
            .header('Content-Type', 'application/json')
            # Make the call
            .post(JSON.stringify(payload)) (err, res, body) ->
              if err
                robot.logger.info "Encountered an error: #{err}"
                msg.send "Encountered an error: #{err}"
                return
              else
                msg.send "Your #{issue_type} has been submited. #{body['url']}"
        else
          msg.reply errors['github-username']
      else
        msg.reply errors['github-usernames']
    else
      msg.reply errors['github-org']
