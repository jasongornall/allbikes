# modules
async = require 'async'
request = require 'request'
xml2js = require 'xml2js'

# tools
parser = new xml2js.Parser {explicitArray: false}


module.exports =
  allowCrossDomain: (req, res, next) ->
    res.header 'Access-Control-Allow-Origin', '*'
    res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE'
    res.header 'Access-Control-Allow-Headers', 'Content-Type'

    if 'OPTIONS' is req.method
      res.send 200
    else
      next()

  calcDistance: (coord1, coord2) ->
    [lat1, lon1] = [coord1.lat, coord1.long]
    [lat2, lon2] = [coord2.lat, coord2.long]
    radlat1 = Math.PI * lat1 / 180
    radlat2 = Math.PI * lat2 / 180
    radlon1 = Math.PI * lon1 / 180
    radlon2 = Math.PI * lon2 / 180
    theta = lon1 - lon2
    radtheta = Math.PI * theta / 180
    dist = Math.sin(radlat1) * Math.sin(radlat2)
    dist += Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta)
    dist = Math.acos(dist)
    dist *= 180 / Math.PI
    dist *= 60 * 1.1515
    dist *= 1609.344
    return Math.floor dist

  get: (resource, done) ->
    {url, id} = resource
    async.waterfall [
      (next) -> request {method: 'GET', url: url}, next
      (resp, body, next) ->
        return next 'resp is undefined. uh oh.' unless resp

        # check for bad status code
        if resp.statusCode < 200 or resp.statusCode > 302
          return next "bad #{body}"

        addCity = ->
          body.map (station) ->
            station.city_id = id
            station

        parseJSON = ->
          try
            body = JSON.parse body
            {stationBeanList} = body
            body = stationBeanList if stationBeanList
            body = addCity()
            return next null, body
          catch err
            return next err

        parseXML = ->
          parser.parseString body, (err, result) ->
            body = result.stations.station
            body = addCity()
            next null, body

        switch resp.headers['content-type']
          when 'application/json', 'application/json; charset=utf-8'
            parseJSON()

          when 'text/html; charset=UTF-8', 'text/html'
            parseJSON()

          when 'application/xml', 'text/xml'
            parseXML()

          when 'text/javascript; charset=utf-8'
            body = body.replace /\\/g, ''
            parseJSON()

          else
            next "Unknown content type | #{url}"

    ], (err, body) ->
      done err, body

  unused_fields: [
    'altitude'
    'city'
    'installDate'
    'installed'
    'landMark'
    'lastCommunicationTime'
    'lastCommWithServer'
    'latestUpdateTime'
    'postalCode'
    'public'
    'removalDate'
    'stAddress1'
    'stAddress2'
    'testStation'
    'terminalName'
    'temporary'
  ]

