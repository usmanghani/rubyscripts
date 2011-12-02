require 'rubygems'
require 'mechanize'
require 'logger'
require 'ostruct'
require 'marshal'

$domainRoot = "http://www.new1.dli.ernet.in"
$baseUrl = "http://www.new1.dli.ernet.in/cgi-bin/advsearch_db.cgi?listStart=%d&language1=Urdu&perPage=%d"

rootDir = ARGV[0]

Dir.mkdir(rootDir) if not File.directory?(rootDir)
Dir.chdir(rootDir)

$logger = Logger.new('dliscript.rb.log')

class String
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end
end

class GroupMetadata
  attr_accessor :group_start
  attr_accessor :group_end
  attr_accessor :download_status
  
  def initialize(start = 0, ending = 0, download_status = 'NotStarted')
    @download_status = download_status
    @group_start = start
    @group_end = ending
  end
  
  def save(IO)
    Marshal.dump(self, IO)
  end
  
  def GroupMetadata.load(IO)
    Marshal.load(IO)
  end
    
end

class BookItem
  attr_accessor :subject
  attr_accessor :year
  attr_accessor :bar_code
  attr_accessor :pages
  attr_accessor :title
  attr_accessor :metadata_link
  attr_accessor :content_link
  attr_accessor :first_page
  attr_accessor :last_page
  attr_accessor :content_path
  attr_accessor :download_status
  
  def initialize(subject=nil, year=nil, bar_code=nil, pages=nil, title=nil, metadata_link=nil, download_status='NotStarted')
    @subject = subject
    @year = year
    @bar_code = bar_code
    @pages = pages
    @title = title
    @metadata_link = metadata_link
    @download_status = download_status
  end
    
  def save(IO)
    Marshal.dump(self, IO)
  end
  
  def BookItem.load(IO)
    Marshal.load(IO)
  end
  
  def BookItem.parse_from_link(link)
    book = BookItem.new  
    tokens = link.split('&')
    tokens.each { |token|
      parts = token.split('=')

      book.subject = parts[1].to_s.strip if parts[0] == 'subject1'
      book.year = parts[1].to_s.strip if parts[0] == 'year'
      book.bar_code = parts[1].to_s.strip if parts[0] == 'barcode'
      book.pages = parts[1].to_s.strip.to_i if parts[0] == 'pages'
      book.title = parts[1].to_s.strip if parts[0] == 'title1'
      book.content_path = parts[1].to_s.strip if parts[0] == 'url'
      book.download_status = 'NotStarted'
    }

    book.first_page = 1
    book.last_page = book.pages
    book.metadata_link = link

    return book  
  end
    
end


def load_log_entries(IO)
  lines = IO.readlines
  urls = lines.each do |line| urls << line.strip; end
  return urls
end
  
  
def get_page_name(page)
  page.to_s.rjust(8, '0')
end

def get_page_name_with_extension(page)
  get_page_name(page) + '.tif'
end

def get_page_url(book, page)
  $domainRoot + book.content_path + '/PTIFF/' + get_page_name_with_extension(page)
end

def get_group_dir_name(start, ending)
  start.to_s + '-' + ending.to_s
end

mechanize = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
  agent.log = $logger
}

cwd = Dir.pwd
(0..2000).step(20).each { |index|
  
  group_dir_name = get_group_dir_name(index, index + 20)
  Dir.chdir(cwd)
  Dir.mkdir(group_dir_name) if not File.directory?(group_dir_name)
  Dir.chdir(group_dir_name)
  
  group_metafile = nil
  grp = nil
  
  if not File.exists?('.gmeta')
    group_metafile = File.open('.gmeta', 'w+')
    grp = GroupMetadata.new(index, index + 20)
    grp.save(group_metafile)
  else
    group_metafile = File.open('.gmeta', 'r+')
    grp = GroupMetadata.load(group_metafile)
  end
  
  if grp.download_status == 'Completed'
    continue
  end
  
  items_list_page = mechanize.get($baseUrl % [index, 20])
  books = []
  items_list_page.links.each { |link|
    book = BookItem.parse_from_link(link.href) if link.href.starts_with?('metainfo.cgi')
    
    if (File.directory? book.bar_code) and (File.exists? (book.bar_code + '/.meta'))
      book_meta = File.open('.meta', 'r+')
      book_temp = BookItem.load(book_meta)
      if book_temp.download_status == 'Completed'
        continue
      end
    end
    
    books.push(book)
  }    
  
  cwd = Dir.pwd
  books.each { |book|
    Dir.chdir(cwd)
    Dir.mkdir book.bar_code if not File.directory? book.bar_code
    Dir.chdir(book.bar_code)
  
    metafile = nil
    if not File.exists?('.meta')
      metafile = File.open('.meta', 'w+')
      book.save(metafile)
    else
      metafile = File.open('.meta', 'r+')
      book = BookItem.load(metafile)
    end
    
    logfile = nil
    last_page_downloaded = book.first_page
    
    if not File.exists?('.log')
      logfile = File.open('.log', 'w+')
    else
      logfile = File.open('.log', 'r+')
      last_page_downloaded = logfile.gets.to_i
      if last_page_downloaded > book.last_page
        logger.info('Last page downloaded in the log file is invalid. Will iterate over all pages to figure out which ones have been downloaded.')
        last_page_downloaded = book.first_page
      else
        last_page_downloaded += 1
      end
    end
    
    (last_page_downloaded .. book.last_page).each { |page|
      page_url = get_page_url(book, page)
      logfile.close
      logfile = File.open('.log', 'w+')
      begin
        $logger.info 'Downloading %s' % page_url
        if not File.exists?(get_page_name_with_extension(page))
          mechanize.get(page_url).save()
          logfile.puts(page)
        else
          $logger.info 'Skipping download of already existing file %s' % get_page_name_with_extension(page)
        end
      rescue
        $logger.error 'Failed to download %s' % page_url
      end
      Time.new
      sleep 5
    }
    
    logfile.close
    
  }
}
