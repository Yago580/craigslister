require 'mechanize'

class InvalidRangeError < StandardError
end

class Craigslister
  attr_reader :area, :item, :high, :low, :results

  def initialize args
    @results = []
    @area = args.fetch(:area, 'sfbay')
    @item = args[:item]
    @high = args.fetch(:high, nil)
    @low  = args.fetch(:low, nil)
    validate_price_range

    @mech = Mechanize.new
    configure_mech
  end

  def scrape
    links.each do |link|
      get_data_from(link)
    end
  end

  def url
    "#{base_url}"\
    "search/sss?sort=rel&"\
    "#{price_query}"\
    "query=#{item.downcase.split(' ') * '+'}"\
  end

  def links
    @mech.get(url)
    @mech.page.search('.hdrlnk').map {|link| link['href']}
  end


  private
    def base_url
      "https://#{area}.craigslist.org/"
    end

    def get_data_from link
      @mech.get(link)
      @results << Item.new(scrape_item_data) rescue p 'no image'
    end

    def scrape_item_data
      {
        image: @mech.page.images[0].src,
        title: @mech.page.at('span.postingtitletext').text.gsub(/ ?- ?\$\d+ ?\(.+\)/, ''),
        price: @mech.page.at('span.postingtitletext span.price').text.gsub(/\$/,'').to_i,
        location: @mech.page.at('span.postingtitletext small').text.gsub(/ ?[\(\)]/,''),
        description: @mech.page.at('section#postingbody').text
      }
    end

    def price_query
      result = ''
      result += "min_price=#{low}&" if low
      result += "max_price=#{high}&" if high
      result
    end

    def configure_mech
      @mech.robots = false
      @mech.user_agent_alias = 'Mac Safari'
    end

    def validate_price_range
      raise InvalidRangeError if (low && high) && low > high
    end
end

class Item
  attr_reader :title, :image, :price, :location

  def initialize args
    @title = args[:title]
    @image = args[:image]
    @price = args[:price]
    @location = args[:location]
  end
end
