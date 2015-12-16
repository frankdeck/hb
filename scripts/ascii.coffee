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
    query = res.match[1] + ".jpg&tbs=isz:s,ic:gray,itp:clipart"
    getUrlList query, (err, imageURLs) ->
      if err
        res.send err
      else
        getQualityURL imageURLs, (err, url) ->
          if err
            res.send err
          else
            writeToFile url, (err, filename) ->
              if err
                res.send err
              else
                convertFile filename, null, (err, text) ->
                  if err
                    res.send err
                  else
                    res.send "```\n#{text}```"

  getUrlList = (query, callback) ->
    gis query, (err, imageURLs) ->
      if err
        console.error err
        callback "there was a problem searching for images", imageURLs
      else
        callback null, imageURLs

  getQualityURL = (imageURLs, callback) ->
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
            
  writeToFile = (url, callback) ->
    filename = '/tmp/image.jpg'
    file = fs.createWriteStream filename
    request(url).pipe(file).on 'close', () ->
      callback null, filename

  convertFile = (filename, width, callback) ->
    graftyWidth = width || process.env.ASCII_CHARACTER_WIDTH
    if !graftyWidth
      callback "the ASCII_CHARACTER_WIDTH has not been set"
    else
      grafty = new Grafty width: graftyWidth
      grafty.convert filename, (err, text) ->
        if err
          console.error err if err
          callback "there was a problem converting the image to ascii"
        else
          lines =  text.split(/\n/).length
          # 50 maximum lines for code blocks in slack and the triple backticks use two of them
          if lines >= 48
            newWidth = graftyWidth - 10
            convertFile filename, newWidth, callback
          else
            callback null, text
