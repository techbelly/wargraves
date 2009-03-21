require 'rubygems'
require 'open-uri'
require 'hpricot'

class SearchResults
  
  USER_AGENT = "Boris the spider"
  
  def initialize(path)
    @path = path
    @page_number = 0
    open(@path,"User-Agent" => USER_AGENT) do |s|
      @current_page = s
      @links = init_links(@current_page,@path)
    end
  end
  
  def next_page
    
  end
  
  def casualty_pages
    @links.select {|s| s =~ /casualty_details\.aspx/}
  end
  
  def result_page_links
    @links.select {|s| s=~ Regexp.new('^'+Regexp.escape("javascript:__doPostBack('dgCasualties$_ctl19")) }
  end
  
  def init_links(page,path)
     links = []
     (Hpricot(page)/"a").each do |a|                
        url = clean_up(a.attributes['href'],path)
        links << url unless (url.nil? or links.include? url)
     end
     links
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


path = "http://www.cwgc.org/search/SearchResults.aspx?=casualty"+
       "&surname=ab&initials=&war=2&"+
       "yearfrom=1941&yearto=1941&force=Army&nationality="
sr = SearchResults.new(path)
