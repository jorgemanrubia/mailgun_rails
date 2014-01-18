module Mailgun
  class Attachment < Tempfile
    attr_reader :original_filename, :content_type

    def initialize (*arg) 
      attachment = arg[0]
      arg[0] = @original_filename = attachment.filename
      @content_type = attachment.content_type.split(';')[0]
      super *arg
      binmode
      write attachment.body.decoded
      rewind
    end
  end
end