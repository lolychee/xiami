require 'typhoeus'
require 'set'

class Spider

  def self.crawl(url, options = {}, &block)
    new(url, options, &block).run
  end

  def initialize(url, options = {}, &block)
    uri = URI(url)
    @site_url = "#{uri.scheme}://#{uri.host}"
    @queue = [].to_set
    @block = block
    push(url)
    self
  end

  def push(url)
    @block.(url)
    request = Typhoeus::Request.new(url)
    request.on_complete do |response|
      queue = parse(response.body) - @queue
      @queue.merge(queue)
      queue.each {|url| push(url) }
    end
    hydra.queue request
  end

  def parse(html)
    Nokogiri::HTML(html).css('a').map do |element|
      if element['href'] =~ /^\//
        @site_url + element['href']
      elsif element['href'] =~ /#{@site_url}/
        element['href']
      end
    end.compact.to_set
  end

  def hydra
    @hydra ||= Typhoeus::Hydra.hydra
  end

  def run
    hydra.run
  end

end