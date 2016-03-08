require 'sinatra'
require 'uri'
if development?
  require 'sinatra/reloader'
  Sinatra.register Sinatra::Reloader
end

#/にpostされたときの処理
post '/' do

  body = request.body.read #postされたテキストをbody変数に
  spstr = body.split("\n") #配列spstrにbodyを改行で分割したものを入れる

  s = String.new #返すテキストを保存するためのstring変数

  spstr.each do |line| #foreachで一行ごとに処理をかけていく
    s << checkLine(line) << "\n"

    # 上の一行は
    # s = s + checkLine(line) + "\n"
    # と同じ意味
  end

  s = "<div class=\"page\"><div>\n" + s[0,s.length - 1] + "\n</div></div>" #最後に整形

  return s #post元に返却

end

#/htmlにpostされたときの処理
post '/html' do

  body = request.body.read #postされたテキストをbody変数に

  if body.match(/^zxcv=/) then # bodyの最初がzxcv=なら（webからのpostのため。zxcv=はformの名前。意味は無い。）
    body = body[5,body.length] # zxcv=を削除する
    body = URI.unescape(body) # URLエンコードをデコードする
    body.gsub!("+"," ") # +を空白に変換する
  end

  spstr = body.split("\n") #配列spstrにbodyを改行で分割したものを入れる

  s = String.new #返すテキストを保存するためのstring変数

  spstr.each do |line|#foreachで一行ごとに処理をかけていく
    s << checkLine(line) << "\n"

    # 上の一行は
    # s = s + checkLine(line) + "\n"
    # と同じ意味
  end

  s = "<html lang=\"ja\"><head><title>NNML</title></head><body><div class=\"page\"><div>\n" + s[0,s.length - 1] + "\n</div></div></body></html>" #最後に整形

  return s #post元に返却

end

#実際に処理をかけるメソッド
def checkLine(line)
  line = checkSpace(line) #[形式段落] 行の最初が空白かどうか
  line = checkRuby(line) #[ルビ] |hoge(fuga)という形式かどうか
  line = checkReturn(line) #[意味段落] 空行かどうか
  line = checkNewPage(line) #[改ページ] -または=が3つ以上のみの行かどうか
  line = checkSharp(line) #[見出し] 最初が#でいくつあるか
  line = checkStrikethrough(line) # [打ち消し線] ~で囲まれているか
  line = checkItalic(line) #[斜体] _で囲まれているか
  line = checkBold(line) #[太字] __で囲まれているか
  line = checkBlockquotes(line) #[引用] 行の最初が>かどうか
  line = checkLink(line) #[リンク/画像] [hoge](fuga)という形式かどうか また、最初に!があるか
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
  s = line.force_encoding("UTF-8").scan(/[\_＿]{1}.*?[\_＿]{1}/)
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
  s = line.force_encoding("UTF-8").scan(/[\_＿]{2}.*?[\_＿]{2}/)
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
