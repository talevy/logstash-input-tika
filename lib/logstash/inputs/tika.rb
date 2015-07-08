# encoding: utf-8

require "logstash/namespace"
require "logstash/environment"
require "logstash/inputs/base"
require 'logstash-input-tika_jars.rb'
require 'base64'

# This plugin will recursively fetch documents found 
# within :path on the local computer and attempt to 
# automatically recognize the file format and collect 
# metadata for the file. It accomplishes this by using the
# Tika library.
#
# Passing the original contents of the document in the form 
# of a base64 encoded string is optional.
#
# === Example, photo library metadata search
#
# [source,ruby] 
#   input {
#     tika {
#       path => "/path/to/photos"
#     }
#   }
class LogStash::Inputs::Tika < LogStash::Inputs::Base
  config_name "tika"

  default :codec, "plain"

  # path on filesystem to recursivly fetch files to fetch 
  # metadata from
  config :path, :validate => :path, :required => true

  # A flag to toggle whether the original document is included 
  # within Event
  config :keep_source, :validate => :boolean, :default => false 

  def register
    @host = Socket.gethostname
  end # def register

  def run(queue)
    Dir.glob("#{@path}/**/*") do |p|
      event = LogStash::Event.new("path" => p, "host" => @host)

      # fetch metadata using Tika
      # TODO(talevy): figure out namespacing, what if 
      # metadata field is called path, host, etc.
      metadata(p).each do |key, val|
        event[key] = val
      end

      if @keep_source
        # TODO(talevy): figure out base64 encoding standards
        # first line's encoding of utf-8 prevents us-ascii to work
        event['_attachement'] = Base64.encode64(File.open(p, 'rb').read).force_encoding('UTF-8')
      end

      decorate(event)
      queue << event
    end
  end # def run 

  private
  def metadata(path)
    # TODO(talevy): error handling
    stream = java.io.FileInputStream.new(path)
    parser = org.apache.tika.parser.AutoDetectParser.new
    handler = org.apache.tika.sax.BodyContentHandler.new
    metadata = org.apache.tika.metadata.Metadata.new

    parser.parse(stream, handler, metadata)

    Hash[ metadata.names.map { |name| [name, metadata.get(name)] } ]
  end
end # class LogStash::Inputs::Tika
