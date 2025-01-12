require 'nokogiri'
require 'open-uri'
require 'sequel'
require 'net/http'


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
  puts "Fetching document from URL: #{url}"
  url = URI.parse(url)
  response = nil
  5.times do |i|
    begin
      response = Net::HTTP.get_response(url)
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