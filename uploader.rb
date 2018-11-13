require 'faraday'
require 'json'

class UploadToGyazo

  GYAZO_URL = 'https://upload.gyazo.com'.freeze

  class << self
    def upload(path:, access_token:)
      conn = create_connection
      params = {
        access_token: access_token,
        imagedata: Faraday::UploadIO.new(path, 'image/jpeg')
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
