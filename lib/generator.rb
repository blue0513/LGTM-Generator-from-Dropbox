require './lib/string.rb'

module Generator
  module Base
    def drawer
      # set common attributes
      Magick::Draw.new {
        self.font = 'Helvetica'
        self.font_weight = Magick::BoldWeight
        self.gravity = Magick::SouthEastGravity
      }
    end

    def attach_transparent_background!(img:, output_file:, width:, height:, alpha: 0.2)
      overlay_img = Magick::Image.new(width, height) {
        self.background_color = 'white'
      }
      overlay_img.alpha(Magick::ActivateAlphaChannel)
      overlay_img.opacity = Magick::QuantumRange - (Magick::QuantumRange * alpha)

      img.composite!(overlay_img, Magick::SouthEastGravity, Magick::OverCompositeOp)
      img.write(output_file)
    end
  end

  module Jpg
    extend Base
    module_function

    # duck type
    def generate!(img:, text:, font_size:, color:, output_file:, cjk_font:)
      cloned = img.dup

      attach_transparent_background!(
        img: cloned,
        output_file: output_file,
        width: text.contains_cjk? ? cloned.columns : (cloned.columns * 3/4),
        height: font_size
      )

      # TODO: position
      drawer.annotate(cloned, 0, 0, 0, 0, text) do
        self.font = cjk_font if text.contains_cjk?
        self.pointsize = font_size
        self.fill = color
      end

      cloned.write(output_file)
    end
  end

  module Gif
    extend Base
    module_function

    # duck type
    def generate!(img:, text:, font_size:, color:, output_file:, cjk_font:)
      image_list = Magick::ImageList.new.tap do |list|
        offsets.each do |offset_x|
          cloned = img.dup

          drawer.annotate(cloned, 0, 0, offset_x, 0, text) do
            self.font = cjk_font if text.contains_cjk?
            self.pointsize = font_size
            self.fill = color
          end

          list << cloned
        end
      end

      image_list.write(output_file)
    end

    def offsets
      # sin curve between 0 and 100
      0.step(2 * Math::PI, 2 * Math::PI / 10.0).map { |x| (Math.cos(x) + 1) * 50 }
    end
  end
end
