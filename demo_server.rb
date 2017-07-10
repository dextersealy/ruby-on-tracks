require 'rack'
require 'optparse'
require_relative 'lib/router'
require_relative 'lib/static'
require_relative 'controllers/gifs_controller'

router = Router.new
router.draw do
  get Regexp.new("^/$"), GifsController, :show
  post Regexp.new("^/search$"), GifsController, :search
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

app = Rack::Builder.new do
  use Static
  run app
end.to_app

options = {}
OptionParser.new do |opts|
  opts.on("-pPORT") do |port|
    options[:port] = port
  end
end.parse!

Rack::Server.start(app: app, Port: options[:port] || 3000)
