module Mailgun
  class Attachment < Tempfile
    attr_reader :original_filename, :content_type

    def initialize (attachment, *rest)
      if rest.select {|opt| opt[:inline] }
        basename = @original_filename = attachment.cid
      else
        basename = @original_filename = attachment.filename
      end
      @content_type = attachment.content_type.split(';')[0]
      super basename, *rest
      binmode
      write attachment.body.decoded
      rewind
    end
  end
end
