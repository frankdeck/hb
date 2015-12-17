# Description:
#   Get an image from google image search in ascii form
#
# Dependencies:
#   "g-i-s": "1.0.1"
#   "grafty": "0.0.5"
#   "request": "2.67.0"
#
# Commands:
#   hubot ascii me <query> - Queries Google Images for <query> and returns a random top result in ascii form.
#
# Author:
#   frankdeck
#

fs      = require "fs"
gis     = require "g-i-s"
Grafty  = require "grafty"
request = require "request"

module.exports = (robot) ->

  robot.respond /ascii me (.*)/i, (res) ->
    query = res.match[1]
    channel = res.message.rawMessage.channel
    res.send "Working on it..."
    getUrlList query, (err, imageURLs) ->
      if err
        res.send "Sorry, #{err}"
      else
        getQualityURL imageURLs, (err, url) ->
          if err
            res.send "Sorry, #{err}"
          else
            writeToFile url, (err, filename) ->
              if err
                res.send "Sorry, #{err}"
              else
                convertFile filename, null, (err, text) ->
                  if err
                    res.send "Sorry, #{err}"
                  else
                    postResponse channel, query, text, (err) ->
                      res.send "Sorry, #{err}" if err

  getUrlList = (query, callback) ->
    query += ".jpg&tbs=isz:s,ic:gray,itp:clipart"
    gis query, (err, imageURLs) ->
      if err
        console.log err
        callback "there was a problem searching for images: #{err}"
      else
        callback null, imageURLs

  getQualityURL = (imageURLs, callback) ->
    try
      position = Math.floor(Math.random() * imageURLs.length)
      if /jpg$/i.test(imageURLs[position])
        request.get(imageURLs[position]).on 'response', (response) ->
          if response.statusCode == 200
            callback null, imageURLs[position]
          else
            imageURLs.splice position, 1
            getQualityURL imageURLs, callback
      else
        imageURLs.splice position, 1
        getQualityURL imageURLs, callback
    catch err
      callback "there was a problem getting a quality URL: #{err}"

  writeToFile = (url, callback) ->
    try
      filename = '/tmp/image.jpg'
      file = fs.createWriteStream filename
      request(url).pipe(file).on 'close', () ->
        callback null, filename
    catch err
      callback "there was a problem writing the image to file: #{err}"

  convertFile = (filename, width, callback) ->
    graftyWidth = width || process.env.ASCII_CHARACTER_WIDTH
    if !graftyWidth
      callback "the ASCII_CHARACTER_WIDTH has not been set"
    else
      grafty = new Grafty width: graftyWidth
      grafty.convert filename, (err, text) ->
        if err
          console.log err
          callback "there was a problem converting the image to ascii: #{err}"
        else
          lines =  text.split(/\n/).length
          # slack limits to 50 lines (for code blocks) and 4000 characters in slack (the triple backticks use two of the lines)
          if lines >= 48 || text.length >= 4000
            newWidth = graftyWidth - 10
            convertFile filename, newWidth, callback
          else
            callback null, text

  postResponse = (channel, query, text, callback) ->
    url   = 'https://slack.com/api/files.upload'
    params =
      channels: channel
      content:  text
      filename: "#{query} - ascii.txt"
      filetype: 'txt'
      token:    process.env.HUBOT_SLACK_TOKEN

    request.post url, form:params, (err, repsonse, body) ->
      if err || JSON.parse(body).ok != true
        err = JSON.parse(body).error if !err
        console.error err
        callback "there was a problem uploading the file to slack: #{err}"
