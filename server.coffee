# Dependencies
express= require 'express'
dhs= require 'difficult-http-server'
bluebird= require 'bluebird'
request= bluebird.promisify(require 'request')

# Environment
process.env.PORT?= 59798
cwd= __dirname

# Setup express
app= express()
app.use dhs {cwd}
app.use '/scrape/',(req,res)->
  # eg. http://localhost:59798/scrape/http://ncode.syosetu.com/n6316bn/1
  url= req.url.slice 1
  request url
  .spread (response,body)->
    res.status response.statusCode
    res.set 'Content-type','text/html'
    res.end body

# Boot
app.listen process.env.PORT,->
  console.log 'Server running at http://localhost:%s',process.env.PORT
