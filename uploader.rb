require 'faraday'
require 'json'

class UploadToGyazo

  GYAZO_URL = 'https://upload.gyazo.com'.freeze

  class << self
    def upload(path:, access_token:, is_gif: false)
      conn = create_connection
      content_type = is_gif ? 'image/gif' : 'image/jpeg'

      params = {
        access_token: access_token,
        imagedata: Faraday::UploadIO.new(path, content_type)
      }

      res = conn.post('/api/upload', params)
      image_url = JSON.parse(res.body)['url']

      image_url
    end

    private

    def create_connection
      Faraday.new(url: GYAZO_URL) do |faraday|
        faraday.request :multipart
        faraday.adapter :net_http
      end
    end
  end
end
