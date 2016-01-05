# Takes an Android Netrunner card name and returns the card image
# References netrunnerdb.com
# [[<cardname>]] - returns card image if it exists

module.exports = (robot) ->
  robot.hear /\[\[(.*)\]\]/i, (res) ->
    cardname = escape(res.match[1])
    baseURL = "http://netrunnerdb.com"

    robot.http(baseURL+"/find/?q=#{cardname}")
      .get() (err, response, body) ->
        try
          # get the card image url. Its the only image on the page
          imageURL = body.match /(src=")([\/\w]+.png)/
          
          # send it to the channel
          res.send baseURL+imageURL[2]
        catch error
          res.send "Card image not found"