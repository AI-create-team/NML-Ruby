
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

  spstr.each do |line|
    line = checkSpace(line)
    checkRuby(line)
    line << "\n"

    s << line
  end

  return s[0,s.length - 1]

end

def checkSpace(line)
  if line.match(/^[ \s]/) then
    line = "<p>" + line + "</p>"
  end
  return line
end

def checkRuby(line)

  s = line.force_encoding("UTF-8").scan(/[\|｜].*?[\(（].*?[\)）]/)

  s.each do |text|
    moji = text[/[\|｜].*?[\(（]/]
    moji = moji[1,moji.length-2]

    ruby = text[/[\(（].*?[\)）]/]
    ruby = ruby[1,ruby.length-2]

    s = "<ruby>" + moji + "<rt>" + ruby + "</rt></ruby>"

    line.sub!(text, s)
  end

  return line

end
