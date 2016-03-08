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

# /で囲まれている部分は正規表現なのでJSにそのまま引用可能と思います。

#形式段落
def checkSpace(line)
  if line.match(/^[ \s]/) then #特定の形式に該当すれば
    line = "<p>" + line + "</p>" #この行の最初と最後にタグを付けて
  end
  return line #返す
end

#意味段落
def checkReturn(line)
  if line == "" then #空行なら
    line = "</div>\n<div>" #タグを付けて
  end
  return line #返す
end

#ルビ
def checkRuby(line)
  s = line.force_encoding("UTF-8").scan(/[\|｜].*?[\(（].*?[\)）]/) #特定の形式に該当すれば（scanというのは複数あった時にarrayにして返すメソッド
  s.each do |text|3 #foreachで一項目ごとに処理をかけていく
    moji = text[/[\|｜].*?[\(（]/] #ルビを書ける文字を取得
    moji = moji[1,moji.length-2] #余計な部分を削除

    ruby = text[/[\(（].*?[\)）]/] #ルビを取得
    ruby = ruby[1,ruby.length-2] #余計な部分を削除

    s = "<ruby>" + moji + "<rt>" + ruby + "</rt></ruby>" #タグを付けて

    line.gsub!(text, s) #lineに埋め込んで(gsub/subは置換。この場合、lineの中のtextをsに置き換え。)

  end
  return line #返す
end

#改ページ
def checkNewPage(line)
  if line.force_encoding("UTF-8").match(/^[-ー=＝]{3,}$/) then #特定の形式に該当すれば
    line = "\n</div>\n</div>\n<div class=\"page\">\n<div>\n" #タグをつけて
  end
  return line #返す
end

#見出し
def checkSharp(line)
  if (md = line.match(/^[#＃]*/).to_s) != "" #特定の形式に該当すれば(この場合、該当したものをstringにして変数mdに代入)
    count = md.length #該当したものの文字数取得
    if count > 6 #文字数が7以上なら
      count = 6 #6にする
    end

    line.sub!(/^[#＃]*/, "") #シャープを削除する
    line = "<h#{count}>#{line}</h#{count}>" #タグを付けて

  end
  return line #返す
end

#打ち消し線
def checkStrikethrough(line)
  s = line.force_encoding("UTF-8").scan(/[\~〜]{2}.*?[\~〜]{2}/) #特定の形式に該当すれば
  s.each do |text| #foreachで一項目ごとに処理をかけていく
    ss = "<s>#{text[2,text.length - 4]}</s>" #タグを付けて
    line.gsub!(text, ss) #lineに埋め込んで
  end
  return line #返す
end

#斜体
def checkItalic(line)
  s = line.force_encoding("UTF-8").scan(/[\_＿*＊]{1}.*?[\_＿*＊]{1}/) #特定の形式に該当すれば
  s.each do |text| #foreachで一項目ごとに処理をかけていく
    if text != "__" #該当したものが_ _じゃなければ的なものだった気がする()
      ss = "<i>#{text[1,text.length - 2]}</i>" #タグを付けて
      line.gsub!(text, ss) #lineに埋め込んで
    end
  end
  return line #返す
end

#太字
def checkBold(line)
  s = line.force_encoding("UTF-8").scan(/[\_＿*＊]{2}.*?[\_＿*＊]{2}/) #特定の形式に該当すれば
  s.each do |text| #foreachで一項目ごとに処理をかけていく
    line.gsub!(text, "<b>#{text[2,text.length - 4]}</b>") #タグを付けてlineに埋め込んで(書き方統一してないなあ。。。ｗ)
  end
  return line #返す
end

#引用 (複数行にまたがるときの挙動が今一つ)
def checkBlockquotes(line)
  if line.match(/^[>＞]/) then #特定の形式に該当すれば
    line = "<blockquote>" + line[1,line.length] + "</blockquote>" #タグを付けて
  end
  return line #返す
end

#リンク
def checkLink(line)
  s = line.force_encoding("UTF-8").scan(/[!！]*\[.*?\][\(（].*?[\)）]/) #特定の形式に該当すれば
  s.each do |text| #foreachで一項目ごとに処理をかけていく

    if text.match(/[!！]{1,}\[.*?\][\(（].*?[\)）]/) then #!が最初についていれば(=画像かどうか)
      if text.match(/\".*\"/) then #マウスオーバーの名前があるかどうか
        linkText = line.match(/\[.*?\]/).to_s.gsub(" ", "") #リンクの文章取得
        url = line.match(/[\(（].*?[\"]/).to_s.gsub(" ", "") #URL取得
        name = line.match(/[\"].*?[\"]/).to_s.gsub(" ", "") #マウスオーバーの文章取得
        line.gsub!(text, "<img src=\"#{url[1,url.length-2]}\" alt=\"#{linkText[1,linkText.length-2]}\" title=\"#{name[1,name.length-2]}\">") #タグを付けて置換して
      else
        linkText = line.match(/\[.*?\]/).to_s.gsub(" ", "") #リンクの文章取得
        url = line.match(/[\(（].*?[\)）]/).to_s.gsub(" ", "") #URL取得
        line.gsub!(text, "<img src=\"#{url[1,url.length-2]}\" alt=\"#{linkText[1,linkText.length-2]}\" >")
      end
    else#画像じゃないければ
      if text.match(/\".*\"/) then #マウスオーバーの名前があるかどうか
        linkText = line.match(/\[.*?\]/).to_s.gsub(" ", "") #リンクの文章取得
        url = line.match(/[\(（].*?[\"]/).to_s.gsub(" ", "") #URL取得
        name = line.match(/[\"].*?[\"]/).to_s.gsub(" ", "") #マウスオーバーの文章取得
        line.gsub!(text, "<a href=\"#{url[1,url.length-2]}\" title=\"#{name[1,name.length-2]}\">#{linkText[1,linkText.length-2]}</a>")
      else
        linkText = line.match(/\[.*?\]/).to_s.gsub(" ", "") #リンクの文章取得
        url = line.match(/[\(（].*?[\)）]/).to_s.gsub(" ", "") #URL取得
        line.gsub!(text, "<a href=\"#{url[1,url.length-2]}\">#{linkText[1,linkText.length-2]}</a>")
      end
    end

  end
  return line #返す
end
