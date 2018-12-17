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
@text = 'LGTM'
@color = 'red'
@size = nil

## Methods ##

def download_image(client:, download_image_name:)
  filename =
    File.extname(download_image_name) == '.gif' ? ORIGINAL_GIF_NAME : ORIGINAL_IMAGE_NAME

  client.download(download_image_name) do |chunk|
    open(filename, 'wb') do |file|
      file << chunk
    end
  end
end

def generate_lgtm(file:, text:, color:, size:, gif_text:, cjk_font:, background:, use_gif:)
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

  if use_gif
    generator = Generator::Gif
    output_file = OUTPUT_GIF_NAME
  else
    generator = gif_text ? Generator::TextGif : Generator::Jpg
    output_file = gif_text ? OUTPUT_GIF_NAME : OUTPUT_IMAGE_NAME
  end

  generator.generate!(
    img: img,
    text: text,
    color: color,
    font_size: font_size,
    output_file: output_file,
    cjk_font: cjk_font,
    background: background
  )
end

## Read options ##

begin
  params = ARGV.getopts('', 'upload', 'text-gif', 'auto-color', 'history', 'background', 'use-gif', 'color:', 'size:', 'text:')
rescue OptionParser::InvalidOption => e
  puts e
  puts 'Use --help to list available options'
  return
end

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
filename_list = file_list.entries

# Get an image randomly in the directory
# If `use-gif` option is enabled, Only .gif image will be selected
# If `history` option is enabled, The least frequently used image will be adopted
if params['use-gif']
  filename_list = filename_list.select { |file|
    File.extname(file.name) == '.gif'
  }
end

if params['history']
  while true
    file_name = filename_list.sample.name
    puts 'Check by history: ' + file_name
    break if History.should_adopt?(file_name)
  end
else
  file_name = filename_list.sample.name
end
puts 'Adopt: ' + file_name
download_image_name = json_data['target_directory'] + file_name

puts 'Downloading Image ...'
download_image(client: client, download_image_name: download_image_name)

@color = params['color'] if params['color']
@size = params['size'] if params['size']
@text = params['text'] if params['text']
gif_text = params['gif-text']
cjk_font = json_data['cjk_font']
background = params['params']
use_gif = params['use-gif']
filename = use_gif ? ORIGINAL_GIF_NAME : ORIGINAL_IMAGE_NAME

# Select LGTM string's color from inverted high contrast color of original image's average color
if params['auto-color']
  puts 'Auto Color Selecting ...'
  rgb_color = ColorTone.get_average_color_as_rgb(file: filename)
  inverted_rgb_color = ColorTone.calc_inverted_high_contrast_color_as_rgb(rgb_color)

  puts 'Original Color: ' + rgb_color.to_s
  puts 'Selected Color: ' + inverted_rgb_color.to_s
  @color = ColorTone.rgb_to_hex(inverted_rgb_color)
end

puts 'Generating LGTM Image ...'
generate_lgtm(
  file: filename,
  text: @text,
  color: @color,
  size: @size,
  gif_text: gif_text,
  cjk_font: cjk_font,
  background: background,
  use_gif: use_gif,
)

if params['upload']
  puts 'Uploading Image to Gyazo ...'
  gif_type = gif_text || use_gif
  path = gif_type ? OUTPUT_GIF_NAME : OUTPUT_IMAGE_NAME
  access_token = json_data['gyazo_access_token']

  @image_url = UploadToGyazo.upload(path: path, access_token: access_token, is_gif: gif_type)
end

History.write_history(file_name) if params['history']
puts 'Finish!!'
puts @image_url unless @image_url.nil?
