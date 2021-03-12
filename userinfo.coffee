platform = require('platform')
request = require('request')

randomColor = () ->
  return '#' + (0x1000000 + (Math.random()) * 0xffffff).toString(16).substr(1, 6);

module.exports = (ioObject, slackObject, setConnectNotify) ->
  io = ioObject
  slack = slackObject
  users = {}

  addUser: (req) ->
    user =
      nick: req.data.nick
      platform: platform.parse(req.headers['user-agent'])
      ip:
        public: req.headers['x-forwarded-for']
        local: []
    users[req.io.socket.id] = user

  removeUser: (id)->
    if !!users[id]
      nick = users[id].nick
      setTimeout ->
        delete users[id]
      , 60000
      nick

  addUserIp: (req) ->
    user = users[req.io.socket.id]
    user.ip.local.push req.data.localip if user

  getOnlineUsers: ()->
    onlineUsers = []
    for id, user of users
      onlineUsers.push user.nick
    onlineUsers

  interpret: (message) ->
    index = message.indexOf(' ')
    if index == -1
      command = message
      nick = ''
    else
      command = message.substr(0, index)
      nick = message.substr(index + 1)
    command = command.toLowerCase()
    if command == 'info'
      if nick == ''
        slack.postMessage "No nick supplied", process.env.SLACK_CHANNEL, 'Jinora'
        return
      userExist = Object.keys(users).some (id) ->
        user = users[id]
        if user.nick == nick
          text = "Info for #{nick}:\n"
          text += "\t*Platform:* #{user.platform}\n"
          text += "\t*Public ip:* #{user.ip.public}\n"
          text += "\t*Local ip:* #{user.ip.local.join '|'}"
          attachments = [
            {
              "color": randomColor()
              "pretext": "Info for #{nick}:"
              "title": "#{nick}"
              "text": "*Platform:* #{user.platform}" +
                "\n*Public ip:* #{user.ip.public} " +
                "\n*Local ip:* #{user.ip.local.join '|'}"
            }
          ]
          if user.ip.public
            request.get {url: "http://ipwhois.app/json/#{user.ip.public}", json: true}, (err, res, data)->
              if !err
                text += "\n\t*Location:* #{data.city}, #{data.region}, #{data.country}"
                text += "\n\t*Org:* #{data.org}, *ISP*: #{data.isp}"
                attachments[0]["fallback"] = text
                attachments[0]["text"] += "\n*Location:* #{data.city}, #{data.region}, #{data.country}"
                attachments[0]["footer"] = "#{data.org}, #{data.isp}"

              slack.postMessage "", process.env.SLACK_CHANNEL, 'Jinora', null, attachments
          return true
        false
      slack.postMessage "No such user found", process.env.SLACK_CHANNEL, 'Jinora' if !userExist

