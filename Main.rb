require 'sinatra'
require 'uri'
if development?
  require 'sinatra/reloader'
  Sinatra.register Sinatra::Reloader
end

post '/' do

  body = request.body.read
  spstr = body.split("\n")

  s = String.new

  spstr.each do |line|
    s << checkLine(line) << "\n"
  end

  s = "<div class=\"page\"><div>\n" + s[0,s.length - 1] + "\n</div></div>"

  return s

end

post '/html' do

  body = request.body.read


  if body.match(/^zxcv=/) then
    body = body[5,body.length]
    body = URI.unescape(body)
    body.gsub!("+"," ")
  end

  spstr = body.split("\n")

  s = String.new

  spstr.each do |line|
    s << checkLine(line) << "\n"
  end

  s = "<html lang=\"ja\"><head><title>NNML</title></head><body><div class=\"page\"><div>\n" + s[0,s.length - 1] + "\n</div></div></body></html>"

  return s

end

def checkLine(line)
  line = checkSpace(line)
  line = checkRuby(line)
  line = checkReturn(line)
  line = checkNewPage(line)
  line = checkSharp(line)
  line = checkStrikethrough(line)
  line = checkItalic(line)
  line = checkBold(line)
  line = checkBlockquotes(line)
  line = checkLink(line)
  return line
end

#形式段落
def checkSpace(line)
  if line.match(/^[ \s]/) then
    line = "<p>" + line + "</p>"
  end
  return line
end

#意味段落
def checkReturn(line)
  if line == "" then
    line = "</div>\n<div>"
  end
  return line
end

#ルビ
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

#改ページ
def checkNewPage(line)
  if line.force_encoding("UTF-8").match(/^[-ー=＝]{3,}$/) then
    line = "\n</div>\n</div>\n<div class=\"page\">\n<div>\n"
  end
  return line
end

#見出し
def checkSharp(line)
  if (md = line.match(/^[#＃]*/).to_s) != ""
    count = md.length
    if count > 6
      count = 6
    end

    line.sub!(/^[#＃]*/, "")
    line = "<h#{count}>#{line}</h#{count}>"

  end
  return line
end

#打ち消し線
def checkStrikethrough(line)
  s = line.force_encoding("UTF-8").scan(/[\~〜]{2}.*?[\~〜]{2}/)
  s.each do |text|
    ss = "<s>#{text[2,text.length - 4]}</s>"
    line.gsub!(text, ss)
  end
  return line
end

#斜体
def checkItalic(line)
  s = line.force_encoding("UTF-8").scan(/[\_＿*＊]{1}.*?[\_＿*＊]{1}/)
  s.each do |text|
    if text != "__"
      ss = "<i>#{text[1,text.length - 2]}</i>"
      line.gsub!(text, ss)
    end

  end
  return line
end

#太字
def checkBold(line)
  s = line.force_encoding("UTF-8").scan(/[\_＿*＊]{2}.*?[\_＿*＊]{2}/)
  s.each do |text|
    line.gsub!(text, "<b>#{text[2,text.length - 4]}</b>")
  end
  return line
end

#引用 (複数行にまたがるときの挙動が今一つ)
def checkBlockquotes(line)
  if line.match(/^[>＞]/) then
    line = "<blockquote>" + line[1,line.length] + "</blockquote>"
  end
  return line
end

#リンク
def checkLink(line)
  s = line.force_encoding("UTF-8").scan(/[!！]*\[.*?\][\(（].*?[\)）]/)
  s.each do |text|

    if text.match(/[!！]{1,}\[.*?\][\(（].*?[\)）]/) then
      if text.match(/\".*\"/) then
        #""に該当
        linkText = line.match(/\[.*?\]/).to_s.gsub(" ", "")
        url = line.match(/[\(（].*?[\"]/).to_s.gsub(" ", "")
        name = line.match(/[\"].*?[\"]/).to_s.gsub(" ", "")
        line.gsub!(text, "<img src=\"#{url[1,url.length-2]}\" alt=\"#{linkText[1,linkText.length-2]}\" title=\"#{name[1,name.length-2]}\">")
      else
        linkText = line.match(/\[.*?\]/).to_s.gsub(" ", "")
        url = line.match(/[\(（].*?[\)）]/).to_s.gsub(" ", "")
        line.gsub!(text, "<img src=\"#{url[1,url.length-2]}\" alt=\"#{linkText[1,linkText.length-2]}\" >")
      end
    else#画像じゃないければ
      if text.match(/\".*\"/) then
        #""に該当
        linkText = line.match(/\[.*?\]/).to_s.gsub(" ", "")
        url = line.match(/[\(（].*?[\"]/).to_s.gsub(" ", "")
        name = line.match(/[\"].*?[\"]/).to_s.gsub(" ", "")
        line.gsub!(text, "<a href=\"#{url[1,url.length-2]}\" title=\"#{name[1,name.length-2]}\">#{linkText[1,linkText.length-2]}</a>")
      else
        linkText = line.match(/\[.*?\]/).to_s.gsub(" ", "")
        url = line.match(/[\(（].*?[\)）]/).to_s.gsub(" ", "")
        line.gsub!(text, "<a href=\"#{url[1,url.length-2]}\">#{linkText[1,linkText.length-2]}</a>")
      end
    end

  end
  return line
end
