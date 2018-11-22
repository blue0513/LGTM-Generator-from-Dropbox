module Color
  module_function

  def get_average_color_as_rgb(file:)
    img =  Magick::Image.read(file).first
    pix = img.scale(1, 1)

    # To adjust RGB value from 0 to 255,
    # We need to divide the value by Magick::QuantumRange
    red = (pix.pixel_color(0,0).red * 255.0 / Magick::QuantumRange).to_i
    green = (pix.pixel_color(0,0).green * 255.0 / Magick::QuantumRange).to_i
    blue = (pix.pixel_color(0,0).blue * 255.0 / Magick::QuantumRange).to_i

    { red: red, green: green, blue: blue }
  end

  def to_inverted_color_as_rgb(rgb_hash)
    max = rgb_hash.max { |a, b| a[1] <=> b[1] }
    min = rgb_hash.min { |a, b| a[1] <=> b[1] }
    val = max[1] + min[1]

    r = 255 - rgb_hash[:red]
    g = 255 - rgb_hash[:green]
    b = 255 - rgb_hash[:blue]

    { red: r, green: g, blue: b }
  end

  def rgb_to_hex(r, g, b)
    "##{to_hex r}#{to_hex g}#{to_hex b}"
  end

  def to_hex(n)
    n.to_s(16).rjust(2, '0').upcase
  end
end
