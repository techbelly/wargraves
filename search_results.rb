require 'rubygems'
require 'net/http'
require 'uri'
require 'open-uri'
require 'nokogiri'

class SearchResults
  
  USER_AGENT = "Boris the spider"
  
  def initialize(path)
    @path = path
    @page_number = 0
    open(@path,"User-Agent" => USER_AGENT) do |s|
      @casualties,@web_form,@next_page = init_links(s,@path)
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
      continue = next_page
    end while (continue)
    all_casualties
  end
  
  def next_page
    url = "http://www.cwgc.org/search/"+@web_form.delete('action')
    if @next_page
      @page_number = @page_number + 1
      @web_form['__EVENTTARGET'] = munge_jscript(@next_page)
      res = post_form(URI.parse(url), @web_form)
      @casualties,@web_form,@next_page = init_links(res.body,@path)
      return true
    else
      return false
    end
  end
  
  def munge_jscript(link)
    link = link.gsub("javascript:__doPostBack('","")
    link = link.gsub("','')","")
    link
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
  
  def find_event_target(links)
    # find the lowest numbered continuation link
    # after the current page...
    links = result_page_links(links)
    found_hole = false
    ["00","01","02","03","04","05","06","07","08","09","10"].each do |e|
      link = links.select{|s| s=~ Regexp.new(Regexp.escape("$ctl#{e}"))}
      if link.empty?
        if found_hole
          return nil
        else
          found_hole = true
        end
      elsif found_hole
        return link.first
      end  
    end
    return nil
  end
  
  def form_as_hash(h)
    attributes = {}
    h.css("form").each do |f| 
      attributes['action'] = f['action'] 
    end
    h.css("form input").each do |i|
      attributes[i['name']] = i['value']
    end
    attributes
  end
  
  def casualty_pages(links)
    links.select {|s| s =~ /casualty_details\.aspx/}
  end
  
  def result_page_links(links)
    links.select {|s| s=~ Regexp.new('^'+Regexp.escape("javascript:__doPostBack('dgCasualties$ctl19")) }
  end
  
  def init_links(page,path)
     links = []
     h = Nokogiri::HTML(page)
     h.css("a").each do |a|                
        url = clean_up(a['href'],path)
        links << url unless (url.nil? or links.include? url)
     end
     next_page = find_event_target(links)
     [casualty_pages(links),form_as_hash(h),next_page]
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

