require 'rubygems'
require 'net/http'
require 'uri'
require 'open-uri'
require 'hpricot'
Hpricot.buffer_size = 262144

class SearchResults
  
  USER_AGENT = "Boris the spider"
  
  def initialize(path)
    @path = path
    @page_number = 0
    open(@path,"User-Agent" => USER_AGENT) do |s|
      @casualties,@web_form = init_links(s,@path)
    end
  end
  
  def all_casualties
    all_casualties = []
    begin
      initial_length = all_casualties.length
      all_casualties = all_casualties + @casualties
      all_casualties.uniq!
      new_casualties = (all_casualties.length > initial_length)
      puts "Page #{@page_number+1} - have #{all_casualties.length} casualties"
      next_page
    end while (new_casualties)
    all_casualties
  end
  
  def next_page
    url = "http://www.cwgc.org/search/"+@web_form.delete('action')
    @page_number = @page_number + 1
    @web_form['__EVENTTARGET'] = "dgCasualties:_ctl19:_ctl#{@page_number}"
    res = post_form(URI.parse(url), @web_form)
    @casualties,@web_form = init_links(res.body,@path)
  end
  
  def post_form(url,params)
    req = Net::HTTP::Post.new(url.path+"?"+url.query)
    req.form_data = params
    Net::HTTP::new(url.host, url.port).start do |http|
        http.request(req)
    end
  end
  
  def casualties
    @casualties
  end
  
  def form_as_hash(h)
    attributes = {}
    (h/"form").each do |f| 
      attributes['action'] = f.attributes['action'] 
    end
    (h/"form input").each do |i|
      attributes[i.attributes['name']] = i.attributes['value']
    end
    attributes
  end
  
  def casualty_pages(links)
    links.select {|s| s =~ /casualty_details\.aspx/}
  end
  
  def result_page_links(links)
    links.select {|s| s=~ Regexp.new('^'+Regexp.escape("javascript:__doPostBack('dgCasualties$_ctl19")) }
  end
  
  def init_links(page,path)
     links = []
     h = Hpricot(page)
     (h/"a").each do |a|                
        url = clean_up(a.attributes['href'],path)
        links << url unless (url.nil? or links.include? url)
     end
     [casualty_pages(links),form_as_hash(h)]
  end 
  
  def clean_up(url,path)
    unless url =~ /^javascript/
      url = absolute(url,path)
      return nil if reject?(url)
    end
    return url
  end
  
  def absolute(link,path)
    if link.include? '#'
      link = link[0..link.index('#')-1] 
    end

    if link =~ /^http\:/
      url = URI.join(URI.escape(link))                
    else
      uri = URI.parse(@path)
      host = "#{uri.scheme}://#{uri.host}"
      url = URI.join(host, URI.escape(link))
    end
    url.normalize.to_s
  end
  
  def reject?(url)
    do_not_crawl = %w(.pdf .doc .xls .ppt .mp3 .m4v .avi .mpg .rss .xml .json .txt .git .zip .md5 .asc .jpg .gif .png)
    return true if url.nil?
    return true if do_not_crawl.include? url[(url.size-4)..url.size]
    return true unless url =~ /^http:\/\/www.cwgc.org\//
    return false
  end
  
 
end

