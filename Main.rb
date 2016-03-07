require 'bundler/setup'
Bundler.require
require 'sinatra'
if development?
  require 'sinatra/reloader'
  Sinatra.register Sinatra::Reloader
end

post '/' do

  p request.body.read.split("\n")

end
