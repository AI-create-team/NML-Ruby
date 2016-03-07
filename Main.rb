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
    line = checkRuby(line)
    line = checkReturn(line)
    line = checkNewPage(line)

    line << "\n"

    s << line
  end

  s = "<div class=\"page\"><div>\n" + s[0,s.length - 1] + "\n</div></div>"

  return s

end

post '/html' do

  body = request.body.read

  if body.match(/^zxcv=/) then
    body = body[5,body.length]
  end

  spstr = body.split("\n")

  s = String.new

  spstr.each do |line|
    line = checkSpace(line)
    line = checkRuby(line)
    line = checkReturn(line)
    line = checkNewPage(line)

    line << "\n"

    s << line
  end

  s = "<html lang=\"ja\"><head><title>NNML</title></head><body><div class=\"page\"><div>\n" + s[0,s.length - 1] + "\n</div></div></body></html>"

  return s

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

    line.gsub!(text, s)
  end
  return line
end

def checkReturn(line)
  if line == "" then
    line = "</div>\n<div>"
  end
  return line
end

def checkNewPage(line)
  if line.force_encoding("UTF-8").match(/^[-ー=＝]{3,}$/) then
    line = "\n</div>\n</div>\n<div class=\"page\">\n<div>\n"
  end
  return line
end
