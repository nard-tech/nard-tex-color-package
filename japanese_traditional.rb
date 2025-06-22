# frozen_string_literal: true

require 'yaml'

class Color
  def initialize(r, g, b)
    @r = r.to_i
    @g = g.to_i
    @b = b.to_i
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

  def rgb_h(string_key: false)
    h = { r:, g:, b: }
    string_key ? h.transform_keys(&:to_s) : h
  end

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
  class << self
    def load(h)
      name = h['name']
      name_en = h['name_en']

      r = h['color']['rgb']['r']
      g = h['color']['rgb']['g']
      b = h['color']['rgb']['b']

      note = h['note']

      new(name, name_en, Color.new(r, g, b), note:)
    end
  end

  def initialize(name, name_en, color, rgb_01: nil, note: nil)
    @name = name
    @name_en = name_en
    @color = color

    @rgb_01 = rgb_01
    @note = note
  end

  attr_reader :name, :name_en, :color, :rgb_01, :note

  def to_s
    comment = "% #{name} #{name_en} #{color.hex}, (r,g,b)=(#{color})"
    definecolor = "\\definecolor{#{name_en}}{rgb}{#{color.rgb_01}}"

    if note
      [comment, "% NOTE: #{note}", definecolor].join("\n") + "\n"
    else
      [comment, definecolor].join("\n") + "\n"
    end
  end

  def to_h(string_key: false)
    h = { name:, name_en:, color: color.to_h(string_key:) }
    string_key ? h.transform_keys(&:to_s) : h
  end
end

yaml_string = File.open('japanese_traditional.yml', 'r:utf-8')
               .read
contents = YAML.load(yaml_string)
japanese_traditional_colors = contents.map { |h| JapaneseTraditionalColor.load(h) }

# japanese_traditional_colors.each { puts _1.to_s }

File.open('japanese_traditional.sty', 'w:utf-8') do |f|
  f.write(japanese_traditional_colors.map(&:to_s).join("\n"))
end
