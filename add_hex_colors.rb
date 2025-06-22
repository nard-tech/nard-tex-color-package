# frozen_string_literal: true

class Color
  def initialize(r, g, b)
    @r = r
    @g = g
    @b = b
  end

  attr_reader :r, :g, :b

  def to_a
    [r, g, b]
  end

  def to_s
    to_a.map(&:to_s).join(', ')
  end

  def to_h(string_key: false)
    h = { rgb: rgb_h(string_key:), hex: }
    string_key ? h.transform_keys(&:to_s) : h
  end

  def hex
    '#' + to_a.map { |color| color.to_i.to_s(16).rjust(2, '0') }.join
  end

  def rgb_01(digit = 3)
    rgb_01_as_array(digit).map(&:to_s).join(', ')
  end

  def rgb_01_as_array(digit = 3)
    [r_01(digit), g_01(digit), b_01(digit)]
  end

  private

  def r_01(digit = 3)
    color_01(r, digit)
  end

  def g_01(digit = 3)
    color_01(g, digit)
  end

  def b_01(digit = 3)
    color_01(b, digit)
  end

  def color_01(v, digit = 3)
    result = (v / 255.0).round(digit)

    return 0 if result.zero?
    return 1 if result == 1

    result
  end
end

class JapaneseTraditionalColor
  PATTERN = /\A% ([\p{Han}\p{hiragana}（）→・\d]+) (\w+) \#[0-9a-f]{6}\, \(r,g,b\)=\((\d+), (\d+), (\d+)\)\n\\definecolor\{\w+\}\{rgb\}\{(\d(?:\.\d{,3})?), (\d(?:\.\d{,3})?), (\d(?:\.\d{,3})?)\}\n?\z/

  class << self
    def parse(content)
      PATTERN =~ content

      name = Regexp.last_match(1)
      name_en = Regexp.last_match(2)
      r = Regexp.last_match(3).to_i
      g = Regexp.last_match(4).to_i
      b = Regexp.last_match(5).to_i
      rgb_01 = Regexp.last_match(6)

      new(name, name_en, Color.new(r, g, b), rgb_01)
    end
  end

  def initialize(name, name_en, color, rgb_01)
    @name = name
    @name_en = name_en
    @color = color
    @rgb_01 = rgb_01
  end

  attr_reader :name, :name_en, :color, :rgb_01

  def to_s
    <<~TEX
      % #{name} #{name_en} #{color.hex}, (r,g,b)=(#{color})
      \\definecolor{#{name_en}}{rgb}{#{color.rgb_01}}
    TEX
  end

  def valid_rgb_01?
    rgb_01.split(/,/).map(&:to_f) == color.rgb_01_as_array(1)
  end

  private

  def rgb_01_as_array
    rgb_01.split(/,/).map(&:to_f)
  end
end

contents = File.open('japanese_traditional.sty', 'r:utf-8')
               .read
               .split(/\n{2}/)

contents = contents.map { |content| JapaneseTraditionalColor.parse(content) }

raise if contents.all?(&:valid_rgb_01?)

# contents.each { puts _1.to_s }

File.open('japanese_traditional.sty', 'w:utf-8') do |f|
  f.write(contents.map(&:to_s).join("\n"))
end
