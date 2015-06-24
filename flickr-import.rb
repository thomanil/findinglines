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


def my_photos
  api_key = File.open("flickr-api-key").read.strip
  flickr = Flickr.new(api_key)
  user = flickr.users('tegnethomas@yahoo.no')
  photos = user.photos
end

require "json"

my_photos.each do |photo|
  title = photo.title
  description = photo.description
  taken = photo.taken
  url = photo.url

  if title.include? "IMAG"
    title = ""
  end

  folder_name = File.join("content", taken.gsub(" ","---").gsub(":", "-"))

  if Dir.exist?(folder_name)
    puts "Already present: #{taken}"
  else
    puts "Downloading: #{taken}"

    `mkdir -p #{folder_name}`

    metadata = {
      :title => "TODO",
      :notes => "TODO",
      :timestamp => "TODO",
      :url => "TODO"
    }

    pic_path = File.join(folder_name, photo.filename)
    File.open(pic_path, 'w+') do |file|
      file.puts photo.file
    end
    metadata_path = File.join(folder_name, "metadata.json")
    File.open(metadata_path, 'w+') do |file|
      file.puts metadata.to_json
    end
  end
end
