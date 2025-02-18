require 'nokogiri'
require 'open-uri'
require 'sequel'
require 'net/http'

USER_AGENTS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/537.36 (KHTML, like Gecko) Version/14.1.1 Mobile/15E148 Safari/537.36'
]

DB = Sequel.sqlite('products.db')
DB.create_table? :products do
  primary_key :id
  String :title
  String :price
  String :reviews
  String :product_link
end
class Product < Sequel::Model(:products); end

def fetch_doc_from_url(url)
  url = URI.parse(url)
  response = nil

  5.times do |i|
    begin
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')

      request = Net::HTTP::Get.new(url)
      request['User-Agent'] = USER_AGENTS.sample  # Random User-Agent
      request['Accept-Language'] = 'en-US,en;q=0.9' 
      request['Referer'] = 'https://www.google.com/'

      response = http.request(request)

      while response.is_a?(Net::HTTPRedirection)
        if response['Location'].start_with?('http')
          url = URI.parse(response['Location'])
        else
          url = URI.parse("https://www.amazon.pl/" + response['Location'])
        end
        response = Net::HTTP.get_response(url)
      end

      puts "Attempt #{i + 1} returned status: #{response.code} #{response.message}"
      break if response.is_a?(Net::HTTPSuccess)
    rescue StandardError => e
      puts "Attempt #{i + 1} failed: #{e.message}"
    end
    if i < 4
        sleep(2**i)
    end
  end

  raise "Failed to fetch the page" unless response.is_a?(Net::HTTPSuccess)
  Nokogiri::HTML(response.body)
end

def fetch_reviews_from_product_details(product_link)
  doc = fetch_doc_from_url(product_link)
  doc.css('span.global-reviews-all').css('span.cr-original-review-content').map(&:text).map(&:strip).join("\n")
end

def fetch_products(url)
    doc = fetch_doc_from_url(url)
  
    product_selector = 'div[role=listitem]'
    title_xpath = 'h2.a-text-normal'
    price_selector = 'span.a-price'
    link_selector = 'a.a-link-normal'
    doc.css(product_selector).each do |product_element|
      title = product_element.css(title_xpath).xpath('./span').text.strip
      price = product_element.css(price_selector).css('span.a-offscreen').first.text
      product_link = 'https://www.amazon.pl' + product_element.css(link_selector).attr('href').value.strip

      reviews = fetch_reviews_from_product_details(product_link)

      Product.create(
          title: title,
          price: price,
          reviews: reviews,
          product_link: product_link
      )
      puts "Processed product: #{title}"
    end

    prods = Product.all
    puts "Total products fetched: #{prods.count}"
    puts "| Title                                    | Price           | Link                                             | Reviews                                               |"
    puts "|------------------------------------------|-----------------|--------------------------------------------------|-------------------------------------------------------|"
    prods.each do |product|
      puts "| #{product.title[0...40].ljust(40)} | #{product.price[0..15].ljust(15)} | #{product.product_link[0...45].ljust(45)}... | #{product.reviews.gsub("\n", "; ")[0...50].ljust(50)}... |"
    end
    puts "Products fetched successfully!"
end

print "Enter a search word: "
search_word = gets.chomp
url = "https://www.amazon.pl/s?k=#{URI.encode_www_form_component(search_word)}"
fetch_products(url)