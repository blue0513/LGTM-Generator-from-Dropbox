require 'bundler/setup'
require 'dropbox_api'
require 'RMagick'
require 'json'
require 'optparse'
require 'color'
require './lib/generator.rb'
require './lib/uploader.rb'
require './lib/color_tone.rb'
require './lib/history.rb'

## Settings ##

ORIGINAL_IMAGE_NAME = 'sample.jpg'.freeze
ORIGINAL_GIF_NAME = 'sample.gif'.freeze
OUTPUT_IMAGE_NAME = 'output.jpg'.freeze
OUTPUT_GIF_NAME = 'output.gif'.freeze
JSON_FILE_PATH = 'settings.json'.freeze
DEFAULT_TEXT = 'LGTM'.freeze
DEFAULT_COLOR = 'red'.freeze

def command_line?
  $PROGRAM_NAME == __FILE__
end

def exit_with_msg(message)
  puts message if command_line?
  exit
end

## Main Class ##

class LgtmGenerator
  class << self
    def execute!(params, json_data)
      Executer.execute!(params, json_data)
    end

    def load_params!
      begin
        params = ARGV.getopts(
          '',
          'upload', 'text-gif', 'auto-color', 'history', 'background', 'use-gif',
          'color:', 'size:', 'text:'
        )
      rescue OptionParser::InvalidOption => e
        puts e
        exit_with_msg('Use --help to list available options')
      end

      params
    end

    def load_json!
      puts 'Reading Settings ...' if command_line?
      open(JSON_FILE_PATH) do |io|
        JSON.load(io)
      end
    end
  end

  class Executer
    class << self
      def download_image!(client:, download_image_name:)
        puts 'Downloading Image ...' if command_line?
        filename =
          File.extname(download_image_name) == '.gif' ? ORIGINAL_GIF_NAME : ORIGINAL_IMAGE_NAME

        client.download(download_image_name) do |chunk|
          open(filename, 'wb') do |file|
            file << chunk
          end
        end
      end

      def resize!(size, img)
        unless size =~ /\dx\d/
          raise '--size option should be like `320x480`'
        end

        raise 'img should be Magick::Image' unless img.is_a?(Magick::Image)

        img.change_geometry!(size) do |cols, rows, im|
          im.resize!(cols, rows)
        end
      end

      def select_generator(params)
        return Generator::Gif if params['use-gif']
        params['text-gif'] ? Generator::TextGif : Generator::Jpg
      end

      def select_output_file(params)
        return OUTPUT_GIF_NAME if params['use-gif']
        params['text-gif'] ? OUTPUT_GIF_NAME : OUTPUT_IMAGE_NAME
      end

      def select_text(params)
        params['text'] ? params['text'] : DEFAULT_TEXT
      end

      def font_size(img, text)
        width = img.columns
        width / text.size
      end

      def validate_params(params)
        params.key?('use-gif') &&
          params.key?('text-gif') &&
          params.key?('size') &&
          params.key?('text') &&
          params.key?('color') &&
          params.key?('auto-color') &&
          params.key?('background')
      end

      def generate_lgtm!(params, json_data, generator)
        raise 'invalid params' unless validate_params(params)

        file = build_image(params)
        text = select_text(params)
        color = modify_color(params, file.filename)
        output_file = select_output_file(params)
        font_size = font_size(file, text)

        puts 'Generating LGTM Image ...' if command_line?
        generator.generate!(
          img: file,
          text: text,
          color: color,
          font_size: font_size,
          output_file: output_file,
          cjk_font: json_data['cjk_font'],
          background: params['background']
        )
      end

      def setup_client(json_data)
        DropboxApi::Client.new(json_data['access_token'])
      end

      # NOTE: DropboxApi's response inclues the parent directory name
      # By rejecting it, we can get just image files' name
      def extract_name_from(file_list, target_directory)
        names = file_list.reject { |file|
          file&.name == File.basename(target_directory)
        }.map(&:name)

        names
      end

      # Get an image randomly in the directory
      # If `use-gif` option is enabled, Only .gif image will be selected
      # If `history` option is enabled, The least frequently used image will be adopted
      def select_only_gif(filename_list)
        filename_list.select { |name|
          File.extname(name) == '.gif'
        }
      end

      def adopt_history(filename_list)
        while true
          file_name = filename_list.sample
          puts 'Check by history: ' + file_name if command_line?
          break if History.should_adopt?(file_name, filename_list)
        end
        file_name
      end

      def download_image_name(json_data, file_name)
        json_data['target_directory'] + file_name
      end

      # Select LGTM string's color from inverted high contrast color of
      # original image's average color
      def auto_color(file)
        puts 'Auto Color Selecting ...' if command_line?
        rgb_color = ColorTone.get_average_color_as_rgb(file: file)
        inverted_rgb_color =
          ColorTone.calc_inverted_high_contrast_color_as_rgb(rgb_color)

        puts 'Original Color: ' + rgb_color.to_s if command_line?
        puts 'Selected Color: ' + inverted_rgb_color.to_s if command_line?

        ColorTone.rgb_to_hex(inverted_rgb_color)
      end

      def upload_to_gyazo(path:, access_token:, is_gif:)
        UploadToGyazo.upload(path: path, access_token: access_token, is_gif: is_gif)
      end

      def upload_image!(json_data, params)
        puts 'Uploading Image to Gyazo ...' if command_line?

        gif_type = params['text-gif'] || params['use-gif']
        path = gif_type ? OUTPUT_GIF_NAME : OUTPUT_IMAGE_NAME
        image_url = upload_to_gyazo(
          path: path, access_token: json_data['gyazo_access_token'], is_gif: gif_type
        )

        puts image_url
        image_url
      end

      def modify_color(params, filename)
        return DEFAULT_COLOR if !params['auto-color'] && !params['color']
        return params['color'] if params['color']
        return auto_color(filename) if params['auto-color']
      end

      def select_target_file_by(history, filename_list)
        filename = history ? adopt_history(filename_list) : filename_list.sample
        exit_with_msg('target file does not found') if filename.nil?
        puts ('Adopt: ' + filename) if command_line?
        filename
      end

      def write_history!(file_name)
        History.write_history(file_name)
      end

      def extract_names(file_list, target_directory, use_gif)
        if use_gif
          name_list = extract_name_from(file_list, target_directory)
          select_only_gif(name_list)
        else
          extract_name_from(file_list, target_directory)
        end
      end

      def fetch_file_list!(client, json_data)
        puts 'Reading Dropbox files ...' if command_line?
        client.
          list_folder(json_data['target_directory'], recursive: true).
          entries
      end

      def build_image(params)
        use_gif = params['use-gif']
        size = params['size']
        file_path = use_gif ? ORIGINAL_GIF_NAME : ORIGINAL_IMAGE_NAME

        image = Magick::Image.read(file_path).first
        image = resize!(size, image) if size

        image
      end

      def select_target_file(file_list, json_data, params)
        filename_list =
          extract_names(file_list, json_data['target_directory'], params['use-gif'])
        select_target_file_by(params['history'], filename_list)
      end

      def should_upload?(params)
        params['upload']
      end

      def should_write_history?(params)
        params['history']
      end

      def execute!(params, json_data)
        client = setup_client(json_data)

        file_list = fetch_file_list!(client, json_data)
        target_file_name =
          select_target_file(file_list, json_data, params)

        download_image!(
          client: client,
          download_image_name: download_image_name(json_data, target_file_name)
        )
        generator = select_generator(params)
        generate_lgtm!(params, json_data, generator)

        upload_image!(json_data, params) if should_upload?(params)
        write_history!(target_file_name) if should_write_history?(params)
      end
    end
  end
end

## Run as Script ##
return unless command_line?

params = LgtmGenerator.load_params!
json_data = LgtmGenerator.load_json!
LgtmGenerator.execute!(params, json_data)

puts 'Finish!!'
