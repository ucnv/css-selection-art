#!/usr/bin/env ruby
# encoding: utf-8
require 'thor'
require 'rmagick'
require 'erb'

class CssSelectionArt < Thor
  desc 'generate <image file> [<text file>]', 'Generates css and html that contains a hidden image drawn with css selection'
  option :font_size, type: :numeric, default: 6
  option :width, type: :numeric, default: 96
  option :char, type: :string, default: '_'
  def generate image_file, text_file = nil
    font_size = options[:font_size]
    width = options[:width]
    char = options[:char]
    image = Magick::Image.read(image_file).first
    source = image.resize_to_fit width
    html = []
    map = {}
    text = text_file.nil? ? '' : open(text_file, 'r:utf-8').read
    text = text.ljust source.columns * source.rows, '_'
    chars = text.gsub(/\s/, '_').split('')
    source.each_pixel do |p, c, r|
      html << "<br>\n" if c == 0 && r != 0
      name = "s%03d-%03d" % [c, r]
      html << "<span class=\"s #{name}\">#{chars.shift.sub('_', char)}</span>"
      color = p.to_color Magick::AllCompliance, false, 8, true
      map[color] = [] unless map[color]
      map[color] << '.' + name
    end
    css = map.collect do |key, values|
      values.collect { |v|
        [
          "%s::selection { background: %s; }" % [v, key],
          "%s::-moz-selection { background: %s; }" % [v, key]
        ].join("\n")
      }.join("\n")
    end
    print ERB.new(DATA.read).run(binding)
  end
end

CssSelectionArt.start ARGV

__END__
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title></title>
<style>
#container {
  font-family: monospace;
  font-size: <%= font_size %>px;
  line-height: 1;
}
#container::selection {
  background: #fff;
}
#container::-moz-selection {
  background: #fff;
}
.s {
  margin: 0;
  padding: 0;
  display: inline-block;
}
<%= css.join("\n") %>
</style>
</head>
<body>
<div id="container">
<%= html.join %>
<br>
</div>
<p>Select above &#x2191;</p>
