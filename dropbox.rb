require 'dropbox_api'
require 'RMagick'
require 'json'

## Settings ##

OUTPUT_IMAGE = 'sample.jpg'.freeze
JSON_FILE_PATH = 'settings.json'.freeze
@text = 'LGTM'
@color = 'red'

## Methods ##

def download_image(client:, download_image_name:)
  client.download(download_image_name) do |chunk|
    open(OUTPUT_IMAGE, 'wb') do |file|
      file << chunk
    end
  end
end

def generate_lgtm(file:, text:, color:)
  img = Magick::Image.read(file).first

  width = img.columns
  size = width / @text.size

  # TODO: position
  lgtm = Magick::Draw.new
  lgtm.annotate(img, 0, 0, 0, 0, text) do
    self.font = 'Helvetica'
    self.pointsize = size
    self.font_weight = Magick::BoldWeight
    self.fill = color
    self.gravity = Magick::SouthEastGravity
  end

  img.write('output.jpg')
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
file_list = client.list_folder(json_data['target_directory'], { recursive: true })

# Get an image randomly in the directory
file_name = file_list.entries.sample.name
download_image_name = json_data['target_directory'] + file_name

puts 'Downloading Image ...'
download_image(client: client, download_image_name: download_image_name)

puts 'Generating LGTM Image ...'
generate_lgtm(file: OUTPUT_IMAGE, text: @text, color: @color)

puts 'Finish!!'
