# Dependencies
express= require 'express'
dhs= require 'difficult-http-server'
bluebird= require 'bluebird'
request= bluebird.promisify((require 'request'),{multiArgs:true})

# Environment
process.env.PORT?= 59798
cwd= __dirname
waybackAPI= 'http://archive.org/wayback/available?url='

# Setup express
app= express()
app.use dhs {cwd}
app.use '/scrape/',(req,res)->
  # eg. http://localhost:59798/scrape/http://ncode.syosetu.com/n6316bn/1
  url= req.url.slice 1
  request url
  .spread (response)->
    if response.statusCode is 404
      request waybackAPI+url
      .spread (response,json)->
        available= JSON.parse json

        request available.archived_snapshots.closest.url

    else
      [response]

  .spread (response)->
    res.status response.statusCode
    res.set 'Content-type','text/html'
    res.end response.body

app.use (req,res)->
  res.redirect '/#'+req.url.replace /\/$/,'?scrollX=99999' # Avoid "Cannot GET /n9669bk/1/"

# Boot
app.listen process.env.PORT,->
  console.log 'Server running at http://localhost:%s',process.env.PORT
