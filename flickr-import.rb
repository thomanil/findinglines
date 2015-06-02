require 'flickr'

# Have to monkeypatch "taken" accessor myself, for some reason not
# implemented (properly?) by flickr gem
class Flickr
  class Photo
    def taken
      info = @client.photos_getInfo('photo_id'=>@id)['photo']
      info['dates']['taken']
    end
    def description
      info = @client.photos_getInfo('photo_id'=>@id)['photo']
      content = info['description']
      if content.is_a? String
        return content
      else
        return ""
      end
    end
  end
end

# Api connect
api_key = File.open("flickr-api-key").read.strip
flickr = Flickr.new(api_key)
user = flickr.users('tegnethomas@yahoo.no')

# Handle photos
user.photos.each do |photo|
  title = photo.title
  description = photo.description
  taken = photo.taken

  puts title
  puts description
  puts taken

  #Save file to disk
  #File.open(photo.filename, 'w') do |file|
  #  file.puts photo.file
  #end

  puts "----"
end



#require 'pry'
#binding.pry
