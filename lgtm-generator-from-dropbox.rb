require 'bundler/setup'
require 'dropbox_api'
require 'RMagick'
require 'json'
require 'optparse'
require './lib/generator.rb'
require './lib/uploader.rb'
require './lib/color.rb'

## Settings ##

ORIGINAL_IMAGE_NAME = 'sample.jpg'.freeze
OUTPUT_IMAGE_NAME = 'output.jpg'.freeze
OUTPUT_GIF_NAME = 'output.gif'.freeze
JSON_FILE_PATH = 'settings.json'.freeze
@text = 'LGTM'
@color = 'red'
@size = nil

## Methods ##

def download_image(client:, download_image_name:)
  client.download(download_image_name) do |chunk|
    open(ORIGINAL_IMAGE_NAME, 'wb') do |file|
      file << chunk
    end
  end
end

def generate_lgtm(file:, text:, color:, size:, gif:)
  img = Magick::Image.read(file).first

  if size
    unless size =~ /\dx\d/
      puts '--size option should be like `320x480`'
      return
    end

    img.change_geometry!(size) do |cols, rows, im|
      im.resize!(cols, rows)
    end
  end

  width = img.columns
  font_size = width / @text.size

  generator = gif ? Generator::Gif : Generator::Jpg
  output_file = gif ? OUTPUT_GIF_NAME : OUTPUT_IMAGE_NAME
  generator.generate!(img: img, text: text, color: color, font_size: font_size, output_file: output_file)
end

## Read options ##

params = ARGV.getopts('', 'upload', 'gif', 'auto-color', 'color:', 'size:', 'text:')

## Execution ##

puts 'Reading Settings ...'
json_data = open(JSON_FILE_PATH) do |io|
  JSON.load(io)
end

# Setup client
client = DropboxApi::Client.new(
  json_data['access_token']
)

puts 'Reading Dropbox files ...'
file_list = client.list_folder(json_data['target_directory'], recursive: true)

# Get an image randomly in the directory
file_name = file_list.entries.sample.name
download_image_name = json_data['target_directory'] + file_name

puts 'Downloading Image ...'
download_image(client: client, download_image_name: download_image_name)

@color = params['color'] if params['color']
@size = params['size'] if params['size']
@text = params['text'] if params['text']
gif = params['gif']

# Select LGTM string's color from inverted color of original image's average color
if params['auto-color']
  puts 'Auto Color Selecting ...'
  rgb_color = Color.get_average_color_as_rgb(file: ORIGINAL_IMAGE_NAME)
  inverted_rgb_color = Color.to_inverted_color_as_rgb(rgb_color)

  # NOTE: RMagick need hex color code
  inverted_hex_color = Color.rgb_to_hex(
    inverted_rgb_color[:red],
    inverted_rgb_color[:green],
    inverted_rgb_color[:blue]
  )

  puts 'Original Color: ' + rgb_color.to_s
  puts 'Selected Color: ' + inverted_rgb_color.to_s
  @color = inverted_hex_color
end

puts 'Generating LGTM Image ...'
generate_lgtm(file: ORIGINAL_IMAGE_NAME, text: @text, color: @color, size: @size, gif: gif)

if params['upload']
  puts 'Uploading Image to Gyazo ...'
  path = params['gif'] ? OUTPUT_GIF_NAME : OUTPUT_IMAGE_NAME
  access_token = json_data['gyazo_access_token']

  @image_url = UploadToGyazo.upload(path: path, access_token: access_token, is_gif: params['gif'])
end

puts 'Finish!!'
puts @image_url unless @image_url.nil?
