require 'typhoeus'
require 'set'

class Spider

  def self.site(url, options = {}, &block)
    uri = URI(url)
    site_url = "#{uri.scheme}://#{uri.host}"
    new(Array(url), {site_url: site_url}.merge(options), &block).run
  end

  def initialize(urls, options = {}, &block)
    urls = Array(urls)
    @site_url = options[:site_url]
    @block = block

    urls.each do |url|
      # request = Typhoeus::Request.new(url)
      # request.on_success do |response|
      #   links = visit(find_links(response.body))
      #   block.(url, links)
      # end
      # hydra.queue << request
      add url
    end
    self
  end

  def add(url)
    if hydra.queued_requests.size > 1000
      queue << url
    else
      request = Typhoeus::Request.new(url)
      request.on_success do |response|
        links = visit(find_links(response.body))
        links.each do |u|
          add u
        end
        @block.(url, links)
      end
      hydra.queue request
    end
  end

  def queue
    @queue ||= []
  end

  def visited
    @visited ||= [].to_set
  end

  def visit(urls)
    links = urls.delete_if {|url| visited.include? url }
    visited.merge(links.to_set)
    links
  end

  def find_links(html)
    Nokogiri::HTML(html).css('a').map do |element|
      if element['href'] =~ /^\//
        @site_url + element['href']
      elsif element['href'] =~ /#{@site_url}/
        element['href']
      end
    end.compact
  end

  def hydra
    @hydra ||= Typhoeus::Hydra.hydra
  end

  def run
    Thread.start do
      while queue.size > 0 || hydra.queued_requests.size > 0
        if hydra.queued_requests.size < 1000
          queue.pop(1000).each do |url|
            add(url)
          end
        else
          Thread.pass
        end
      end
    end

    sleep(2)

    hydra.run
  end

end