module ColorTone
  module_function

  def get_average_color_as_rgb(file:)
    img =  Magick::Image.read(file).first
    pix = img.scale(1, 1)

    # To adjust RGB value from 0 to 1 (float),
    # We need to divide the value by Magick::QuantumRange
    red = 1.0 * pix.pixel_color(0,0).red / Magick::QuantumRange
    green = 1.0 * pix.pixel_color(0,0).green / Magick::QuantumRange
    blue = 1.0 * pix.pixel_color(0,0).blue / Magick::QuantumRange

    { red: red, green: green, blue: blue }
  end

  def calc_inverted_high_contrast_color_as_rgb(rgb_hash)
    rgb = Color::RGB.from_fraction(rgb_hash[:red], rgb_hash[:green], rgb_hash[:blue])
    hsl = rgb.to_hsl

    # invert color
    hsl.hue = (hsl.hue + 180) % 360

    # adjust "high contrast" luminosity
    if hsl.luminosity > 50 # brighter
      hsl.luminosity = hsl.luminosity - 50
    else
      hsl.luminosity = hsl.luminosity + 50
    end

    rgb = hsl.to_rgb
    { red: rgb.r, green: rgb.g, blue: rgb.b }
  end

  def rgb_to_hex(rgb_hash)
    Color::RGB.from_fraction(rgb_hash[:red], rgb_hash[:green], rgb_hash[:blue]).html
  end
end
