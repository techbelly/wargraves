require 'rubygems'
require 'yaml'
require 'hpricot'
require 'open-uri'

class Spider
  
  TO_SPIDER = "spider.yml"
  SPIDERED = "spidered.yml"
  PAGES_PER_RUN = 50
  USER_AGENT = "Boris the spider"
  
  def run
    pages_found = 0
    to_spider = YAML.load_file(TO_SPIDER)
    spidered = YAML.load_file(SPIDERED)
    
    while pages_to_spider?(to_spider,pages_found) 
      page = to_spider.pop
      puts "Loading #{page}"
      begin 
        open(page,"User-Agent" => USER_AGENT) do |s|
          if store(page,s) then
            pages_found = pages_found + 1
          end
          links_from(page,s,to_spider,spidered)
          spidered << page
        end
        #rescue => e
        #puts "** Error crawling #{page} - #{e.inspect}"
      end
      File.open(TO_SPIDER,'w') {|out| YAML.dump(to_spider, out)}
      File.open(SPIDERED,'w') {|out| YAML.dump(spidered, out)}
    end
  end
  
  def pages_to_spider?(pages,pages_found)
    return ! (pages.nil? or pages.empty? or pages_found >= PAGES_PER_RUN)
  end
  
  def store(page,contents) 
    regexp = /http:\/\/www.cwgc.org\/search\/casualty_details.aspx?casualty=(\d+)/
    if match = regexp.match(page)
      puts "Yay! I found #{page} - id #{match[1]}"
      return true
    else 
      return false
    end
  end
  
  def links_from(page,s,to_do,done)
     (Hpricot(s)/"a").each do |a|                
        url = scrub(a.attributes['href'], page)
        to_do << url unless (url.nil? or to_do.include? url or done.include? url)
     end
  end 
  
  def scrub(link,page)
    do_not_crawl = %w(.pdf .doc .xls .ppt .mp3 .m4v .avi .mpg .rss .xml .json .txt .git .zip .md5 .asc .jpg .gif .png)
    return nil if link.nil?
    return nil if do_not_crawl.include? link[(link.size-4)..link.size] 
    return nil if (link.include? '/cgi-bin/') or (link.include? 'javascript') or (link.include? 'mailto')
    return nil if ((link.include? 'http') && !(link.include? 'www.cwgc.org'))
       
    link = link.index('#') == 0 ? '' : link[0..link.index('#')-1] if link.include? '#'
    if link.include? 'http'
        url = URI.join(URI.escape(link))                
    else
         uri = URI.parse(page)
         host = "#{uri.scheme}://#{uri.host}"
         url = URI.join(host, URI.escape(link))
    end
    return url.normalize.to_s
  end
end

s = Spider.new
s.run