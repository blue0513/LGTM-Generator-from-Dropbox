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
  end

  module Jpg
    extend Base
    module_function

    # duck type
    def generate!(img:, text:, font_size:, color:, output_file:)
      cloned = img.dup

      # TODO: position
      drawer.annotate(cloned, 0, 0, 0, 0, text) do
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
    def generate!(img:, text:, font_size:, color:, output_file:)
      image_list = Magick::ImageList.new.tap do |list|
        offsets.each do |offset_x|
          cloned = img.dup

          drawer.annotate(cloned, 0, 0, offset_x, 0, text) do
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
