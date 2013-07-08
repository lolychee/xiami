require 'typhoeus'
require 'set'

class Spider

  def self.site(url, opts = {}, &block)
    uri = URI(URI::escape(url))
    spider = new(url, opts, &block)
    spider.limit_links_like(/^#{uri.scheme}:\/\/#{uri.host}/)
    spider.run
  end

  def initialize(urls, opts = {}, &block)
    @opts = {
      max_concurrency: 200,
      max_request: 1000,
      digg_links: true
    }.merge(opts)

    @hydra = Typhoeus::Hydra.new(max_concurrency: @opts[:max_concurrency])

    @queue = []
    @page_patterns = {}
    @link_patterns = {}
    @keep_link_patterns = []
    @skip_link_patterns = []
    @limit_link_patterns = []

    block.(self) if block_given?

    queue *Array(urls)

    self
  end

  def on_pages_like(*regulars, &block)
    Array(regulars).each do |regular|
      @page_patterns[regular] = block
    end
  end

  def on_links_like(*regulars, &block)
    Array(regulars).each do |regular|
      @link_patterns[regular] = block
    end
  end

  def keep_links_like(*regulars)
    @keep_link_patterns.concat(regulars)
  end

  def skip_links_like(*regulars)
    @skip_link_patterns.concat(regulars)
  end

  def limit_links_like(*regulars)
    @limit_link_patterns.concat(regulars)
  end

  def queue(*urls)
    urls = Array(urls)
    unless queued_requests.size > @opts[:max_request]
      urls.pop(@opts[:max_request]).each do |url|
        @hydra.queue create_request(url)
      end
    end
    @queue.concat(urls)
  end

  def queued_requests
    @hydra.queued_requests
  end

  def visited
    @visited ||= [].to_set
  end

  def visited=(array)
    @visited = array.to_set
  end

  def visit(urls)
    urls = urls.delete_if {|url| visited.include? url }
    visited.merge(urls.to_set)
    urls
  end

  def create_request(url)
    user_agent = File.foreach(File.expand_path("../config/user_agents.txt", __FILE__)).each_with_index.reduce(nil) do |picked,pair|
      rand < 1.0/(1+pair[1]) ? pair[0] : picked
    end

    request = Typhoeus::Request.new(url, followlocation: true, headers: {'User-Agent': user_agent})

    request.on_success do |response|
      uri = URI(URI::escape(response.effective_url))
      urls = Nokogiri::HTML(response.body).css('a').map do |element|
        u = element['href']
        if u =~ /^\//
          "#{uri.scheme}://#{uri.host}" + u
        elsif u =~ /^[http|https]/
          u
        end
      end.compact

      urls = urls.keep_if do |u|
        @limit_link_patterns.inject(true) {|memo, pattern| memo = false unless u =~ pattern; memo } &&
        @keep_link_patterns.inject(false) {|memo, pattern| memo = true if u =~ pattern; memo }
      end unless @keep_link_patterns.empty?

      urls = urls.delete_if do |u|
        @skip_link_patterns.inject(false) {|memo, pattern| memo = true if u =~ pattern; memo }
      end unless @skip_link_patterns.empty?

      urls = visit(urls)
      urls.each do |u|
        @link_patterns.each do |pattern, block|
          block.(u) if u =~ pattern
        end
      end
      queue *urls
    end if @opts[:digg_links]

    @page_patterns.select {|regular| regular =~ url }.each do |k, block|
      block.(request)
    end

    request
  end

  def run
    Thread.start do
      while @queue.size > 0 || queued_requests.size > 0
        if queued_requests.size < @opts[:max_request]
          queue *@queue.pop(@opts[:max_request])
        else
          Thread.pass
        end
      end
    end

    @hydra.run
  end
end