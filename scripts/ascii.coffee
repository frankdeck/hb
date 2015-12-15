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
        getQualityURL imageURLs, (url) ->
          writeToFile url, (filename) ->
            convertFile filename, (text) ->
              res.send "\n```\n#{text}\n```"

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
          callback imageURLs[position]
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
      callback filename

  convertFile = (filename, callback) ->
    grafty = new Grafty width: 100
    grafty.convert filename, (err, text) ->
      console.error err if err 
      callback text
