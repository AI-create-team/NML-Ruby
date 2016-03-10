require 'sinatra'
require 'uri'
require 'cgi'
if development?
  require 'sinatra/reloader'
  Sinatra.register Sinatra::Reloader
end

post '/' do
  s = ''

  body = request.body.read.force_encoding('UTF-8').split("\n")
  body.each do |line|
    line.gsub!("\n","")
    s << checkLine(line) << "\n"
  end

  s = "<div class=\"page\"><div>#{s[0, s.length - 1]}</div></div>"
  return CGI.pretty(s)
end

post '/html' do
  bodyText = request.body.read.force_encoding('UTF-8')

  if bodyText =~ /^zxcv=/
    bodyText = bodyText[5, bodyText.length]
    bodyText = URI.unescape(bodyText)
    bodyText.tr!('+', ' ')
  end

  body = bodyText.split("\n")

  s = ''

  body.each do |line|
    s << checkLine(line) << "\n"
  end

  s = "<html lang=\"ja\"><head><title>NNML</title></head><body><div class=\"page\"><div>#{s[0, s.length - 1]}</div></div></body></html>"

  return CGI.pretty(s)
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
  line = checkPunctuationNumber(line)
  line = checkPunctuationSymbol(line)
  line
end

# 形式段落
def checkSpace(line)
  line = "<p>#{line}</p>" if line =~ /^[ \s]/
  line
end

# 意味段落
def checkReturn(line)
  line = '</div><div>' if line == ''
  line
end

# ルビ
def checkRuby(line)
  s = line.scan(/[\|｜].*?[\(（].*?[\)）]/)
  s.each do |text|
    moji = text[/[\|｜].*?[\(（]/]
    moji = moji[1, moji.length - 2]

    ruby = text[/[\(（].*?[\)）]/]
    ruby = ruby[1, ruby.length - 2]

    line.gsub!(text, "<ruby>#{moji}<rt>#{ruby}</rt></ruby>")
  end
  line
end

# 改ページ
def checkNewPage(line)
  line = '</div></div><div class="page"><div>' if line =~ /^[-ー=＝]{3,}$/
  line
end

# 見出し
def checkSharp(line)
  if (md = line.match(/^[#＃]*/).to_s) != ''

    count = md.length > 6 ? 6 : md.length

    line.sub!(/^[#＃]*/, '')
    line = "<h#{count}>#{line}</h#{count}>"

  end
  line
end

# 打ち消し線
def checkStrikethrough(line)
  s = line.scan(/[\~〜]{2}.*?[\~〜]{2}/)
  s.each do |text|
    line.gsub!(text, "<s>#{text[2, text.length - 4]}</s>")
  end
  line
end

# 斜体
def checkItalic(line)
  s = line.scan(/[\_＿*＊]{1}.*?[\_＿*＊]{1}/)
  s.each do |text|
    line.gsub!(text, "<i>#{text[1, text.length - 2]}</i>") unless text == '__' || text == '＿＿'
  end
  line
end

# 太字
def checkBold(line)
  s = line.scan(/[\_＿*＊]{2}.*?[\_＿*＊]{2}/)
  s.each do |text|
    line.gsub!(text, "<b>#{text[2, text.length - 4]}</b>")
  end
  line
end

# 引用 (複数行にまたがるときの挙動が今一つ)
def checkBlockquotes(line)
  if line =~ /^[>＞]/
    line = "<blockquote>#{line[1, line.length]}</blockquote>"
  end
  line
end

# リンク/画像
def checkLink(line)
  s = line.scan(/[!！]*\[.*?\][\(（].*?[\)）]/)
  s.each do |text|
    if text =~ /[!！]{1,}\[.*?\][\(（].*?[\)）]/
      if text =~ /\".*\"/
        # ""に該当
        linkText = line.match(/\[.*?\]/).to_s
        url = line.match(/[\(（].*?[\"]/).to_s.delete(' ')
        name = line.match(/[\"].*?[\"]/).to_s
        line.gsub!(text, "<img src=\"#{url[1, url.length - 2]}\" alt=\"#{linkText[1, linkText.length - 2]}\" title=\"#{name[1, name.length - 2]}\">")
      else
        linkText = line.match(/\[.*?\]/).to_s
        url = line.match(/[\(（].*?[\)）]/).to_s.delete(' ')
        line.gsub!(text, "<img src=\"#{url[1, url.length - 2]}\" alt=\"#{linkText[1, linkText.length - 2]}\" >")
      end
    else # 画像じゃないければ
      if text =~ /\".*\"/
        # ""に該当
        linkText = line.match(/\[.*?\]/).to_s
        url = line.match(/[\(（].*?[\"]/).to_s.delete(' ')
        name = line.match(/[\"].*?[\"]/).to_s
        line.gsub!(text, "<a href=\"#{url[1, url.length - 2]}\" title=\"#{name[1, name.length - 2]}\">#{linkText[1, linkText.length - 2]}</a>")
      else
        linkText = line.match(/\[.*?\]/).to_s
        url = line.match(/[\(（].*?[\)）]/).to_s.delete(' ')
        line.gsub!(text, "<a href=\"#{url[1, url.length - 2]}\">#{linkText[1, linkText.length - 2]}</a>")
      end
    end
  end
  line
end

#数字区切り
def checkPunctuationNumber(line)
  if line =~ /^[0-9]+\.$/
    line = "<hr class=\"number\">"
  end
  line
end

#記号区切り
def checkPunctuationSymbol(line)
  if line =~ /^[-*ー＊]+\.$/
    line = "<hr class=\"symbol\">"
  end
  line
end
