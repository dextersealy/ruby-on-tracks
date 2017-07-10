require 'net/http'
require 'json'
require_relative '../lib/controller_base'

class GifsController < ControllerBase
  protect_from_forgery

  def show
    @gifs = request("trending", limit: 5, rating: "G")
  end

  def search
    @gifs = request("search", q: params[:keyword], limit: 10, rating: "G",
      lang: "en")
  end

  private
  API_KEY = "3ee60bdcb36d43a9925dde5816acd7cb"

  def request(endpoint, options = {})
    uri = URI("https://api.giphy.com/v1/gifs/#{endpoint}")
    uri.query = URI.encode_www_form(options.merge({ api_key: API_KEY }))
    parse_response(Net::HTTP.get_response(uri))
  end

  def parse_response(res)
    return nil unless res.is_a?(Net::HTTPSuccess)

    data = JSON.parse(res.body)["data"]
    result = data.map do |gif|
      image = gif["images"]["downsized"]
      {
        url: gif["url"],
        image: {
          width: image["width"].to_i,
          height: image["height"].to_i,
          url: image["url"]
        }
      }
    end

    result
  end

end
