# coding: utf-8
module Jekyll

  class ImageMngr < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      markup_regex = /(\S.*\s+)?(https?:\/\/|\/)(\S+)(\s+\d+(\s+\d+)?)?(\s+.+)?/i

      if markup_regex.match(markup)
        @class = ("caption-wrapper " + ($1 || '')).rstrip
        @img = $2 + $3
        @caption = $6.strip if $6

        size_regex = /\s*(\d+)(\s+(\d+))?/
        if size_regex.match($4)
          @width = $1
          @height = $3
        end
      end

      super
    end

    def render(context)
      return "Error processing input, expected syntax: {% img [class name(s)] /url/to/image [width height] [caption] %}" unless @img

      if @caption
        <<~HTML
          <figure class="#{@class}" style="width: #{@width}px">
              <img class="caption" src="#{@img}" width="#{@width}" height="#{@height}" title="#{@caption}">
              <figcaption class="caption-text">#{@caption}</figcaption>
          </figure>
        HTML
      else
        <<~HTML
          <span class="#{@class}" style="width: #{@width}px">
              <img class="caption" src="#{@img}" width="#{@width}" height="#{@height}" title="#{@caption}">
          </span>
	HTML
      end
    end
  end
end

Liquid::Template.register_tag('img', Jekyll::ImageMngr)
