# -*- coding: utf-8 -*-
require 'rake'
require 'time'
require 'nokogiri'

FINDINGLINES_DROPBOX_ROOTDIR = File.expand_path("~/Dropbox/findinglines")

task :default => [:process_uploads, :generate, :deploy]

desc "Wipe the previously generated site"
task :clean do
  progress "Doing cleanup..."
  `rm -rf site`
  `rm -rf tmp`
  `rm -rf ~/.org-timestamps` # Or org-publish will deem things unmodified and do nothing
end

desc "Process uploaded picture(s) - create blog post(s) based on newly uploaded pics in #{FINDINGLINES_DROPBOX_ROOTDIR}/uploads/"
task :process_uploads do
  progress "Processing any uploaded pics..."
  Dir[FINDINGLINES_DROPBOX_ROOTDIR+"/uploads/*"].entries.each do |path|
    generate_blogpost_assets(path)
  end
end

def generate_blogpost_assets(img_src_path)
  basename = File.basename(img_src_path).gsub(".jpg","").gsub(".png","")
  uploaded = File.mtime(img_src_path)
  uploaded_human_readable = uploaded.ctime
  uploaded_parsable = uploaded.strftime("%Y%m%d%M")
  root_name = "#{uploaded_parsable}-#{basename}"
  dest_dir = FINDINGLINES_DROPBOX_ROOTDIR+"/archive"
  fullsize_path = File.join(dest_dir, "pics", root_name+"-full.png")
  thumbnail_path = File.join(dest_dir, "pics", root_name+"-thumb.png")
  orgfile_path = File.join(dest_dir, "posts", root_name+"-post.org")

  if `find #{FINDINGLINES_DROPBOX_ROOTDIR}/archive -type f | grep #{orgfile_path}| wc -l`.to_i > 0
    return
  else
    puts "Generating assets from #{root_name}"
    `convert #{img_src_path} #{fullsize_path}`            # full pic
    `convert #{img_src_path} -resize 600x #{thumbnail_path}` # thumbnail
    File.open(orgfile_path, "w+") do |f|                  # post
      thumbnail_url = "http://findinglines.net/images/"+File.basename(thumbnail_path)
      fullsize_url = "http://findinglines.net/images/"+File.basename(fullsize_path)
      f.write(orgfile_template(uploaded_parsable, uploaded_human_readable, thumbnail_url, fullsize_url))
    end
  end
end

desc "Generate site, mainly from assets fetched from #{FINDINGLINES_DROPBOX_ROOTDIR}/archive/"
task :generate do
  progress "Generating site..."
  prepare_folders_and_assets
  generate_main_pages
  generate_blog
end

desc "Deploy last generated version of the site"
task :deploy do
  progress "Deploying last generated version of site..."
  puts `rsync -arl site/ ninjasti@ninjastic.net:~/public_html/findinglines`
end

desc "Backup blog content"
task :backup do
  progress "Backing up assets from Dropbox..."
  # TODO
  # tar up the dropbox dir
  # stick it in S3 bucket
end


private

def prepare_folders_and_assets
  `mkdir -p site`
  `mkdir -p tmp`
  `rsync -r src/images site`
  `rsync -r #{FINDINGLINES_DROPBOX_ROOTDIR}/archive/pics/* site/images`
  `rsync -r src/stylesheets site`
  `rsync -r src/javascript site`
  `echo "ErrorDocument 404 /404.html" > site/.htaccess`
end

def layouted(content)
  layout = File.read("src/mainpages/layout.html")
  body = layout.gsub("***CONTENT***", content)
end

def generate_main_pages
  main_pages = Dir.glob("./src/mainpages/*").map{|path|File.basename(path)}
  main_pages.each do |name|
    body = File.read("src/mainpages/#{name}")
    File.open("site/#{name}", "w+") do |f|
      if name == "404.html"
        f.write(body)
      else
        f.write(layouted(body))
      end
    end
  end
end

def transform_orgfiles
  html_export_dest = File.dirname(__FILE__)
  `html-org-export #{FINDINGLINES_DROPBOX_ROOTDIR}/archive/posts/ #{html_export_dest}/tmp/`

  blog_posts = []
  Dir.glob("tmp/*.html").each do |exported_html_path|
    html_file =  File.read(exported_html_path)
    doc = Nokogiri::HTML(html_file)
    title = doc.css("title").text || "<untitled>"
    title = "(untitled)" if title == ""
    published = doc.xpath("//meta[@name='generated']").attribute("content").text

    if published != "unpublished"
      published_rfc_3339 = Time.parse(published).xmlschema
      body = doc.css("#content").to_html # Just grabbing the content div, drop the rest
      body = "<span id='date'>#{published}</span>"+body
      filename = File.basename(exported_html_path)

      blog_posts << {:title => title,
        :published => published,
        :published_rfc_3339 => published_rfc_3339,
        :body => body,
        :filename => filename}
    end
  end

  blog_posts.sort_by{|p|Time.parse(p[:published]).tv_sec}.reverse
end

def generate_blog
  archive_links = ""
  atom_entries = ""

  blog_posts = transform_orgfiles
  blog_posts.each_with_index do |post, i|
    name = post[:filename]
    title = post[:title]
    body = post[:body]
    published = post[:published]
    published_rfc_3339 = post[:published_rfc_3339]

    body += "<span id='anav'>"
    body += "<a href='#{blog_posts[i+1][:filename]}'>Previous</a>" if i < (blog_posts.size - 1)
    body += "<a class='right' href='#{blog_posts[i-1][:filename]}'>Next</a>" if i > 0
    body += "</span>"

    # Write actual post to file
    File.open("site/#{name}", "w+") do |f|
      f.write(layouted(body))
    end

    if i == 0 # The first/most recent post is also index.html of site
      File.open("site/index.html", "w+") do |f|
        f.write(layouted(body))
      end
    end

    # Link to it from archive page as well
    archive_links += "<a href='#{name}'>#{published} #{title}</a><br/>"

    # Add Atom feed entry
    atom_entries += atom_entry(title, body, name, published_rfc_3339)
  end

  # Write out the archive page
  archive = "<div id='anav'>#{archive_links}</div>"
  File.open("site/archive.html", "w+") do |f|
    f.write(layouted(archive))
  end

  # Generate atom feed
  feed = atom_feed(atom_entries)
  File.open("site/atom.xml", "w+") do |f|
    f.write(feed)
  end
end

def atom_feed(entries)
  feed = <<FEED
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
        <title>Finding Lines</title>
        <subtitle>Just a guy learning to draw</subtitle>
        <link rel="self" href="http://findinglines.net/atom.xml"/>
        <updated>#{Time.now.xmlschema}</updated>
        <author>
                <name>Thomas Kjeldahl Nilsson</name>
                <email>thomas@kjeldahlnilsson.net</email>
        </author>
        <id>http://findinglines.net/</id>
       #{entries}
</feed>
FEED
end

def atom_entry(title, body, link, published)
  entry = <<ENTRY
<entry>
   <title>#{escaped(published)} - #{escaped(title)}</title>
   <content>#{escaped(published)}</content>
   <link href="#{link}"/>
   <id>http://kjeldahlnilsson.net/#{link}</id>
   <updated>#{published}</updated>
</entry>
ENTRY
end

def escaped(str)
  if str.class == String
    str.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("'", "&apos;").gsub("\"", "&quot;")
  end
end

def orgfile_template(human_readable_time, time, thumbnail_url, fullsize_url)
  <<TEMPLATE
#+TITLE:
#+EMAIL:     thomas@kjeldahlnilsson.net
#+DATE:      #{time}
#+DESCRIPTION:
#+KEYWORDS:
#+LANGUAGE:  en
#+OPTIONS: H:3 num:nil toc:nil @:t ::t |:t ^:t -:t f:t *:t <:t
#+OPTIONS: TeX:t LaTeX:t skip:nil d:nil todo:t pri:nil tags:not-in-toc
#+INFOJS_OPT: view:nil toc:nil ltoc:t mouse:underline buttons:0 path:http://orgmode.org/org-info.js
#+EXPORT_SELECT_TAGS: export
#+EXPORT_EXCLUDE_TAGS: noexport
#+LINK_UP:
#+LINK_HOME:
#+XSLT:

[[#{fullsize_url}][#{thumbnail_url}]]

TEMPLATE
end

def progress(msg)
  puts "          --- Findinglines Rakefile: #{msg} ---"
end
