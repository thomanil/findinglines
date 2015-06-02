require 'flickr'
flickr = Flickr.new('some_flickr_api_key')    # create a flickr client (get an API key from http://api.flickr.com/services/api/)
user = flickr.users('sco@scottraymond.net')
