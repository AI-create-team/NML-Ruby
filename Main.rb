require 'bundler/setup'
Bundler.require
require 'sinatra'
if development?
  require 'sinatra/reloader'
  Sinatra.register Sinatra::Reloader
end

post '/' do

  body = request.body.read
  spstr = body.split("\n")

  s = String.new

  spstr.each do |youso|
    youso = checkSpace(youso)
    youso << "\n"

    s << youso
  end

  return s[0,s.length - 1]

end

def checkSpace(youso)
  if youso.match(/^[ \s]/) then
    youso = "<p>" + youso + "</p>"
  end
  return youso
end
