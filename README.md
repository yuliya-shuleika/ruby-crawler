# Ruby Crawler

## Overview

This project is a Ruby-based web crawler designed to scrape product details from Amazon (or Allegro). It utilizes the `Nokogiri` library for parsing HTML, `Net::HTTP` for fetching web pages, and `Sequel` for interacting with an SQLite database.

The crawler retrieves basic product details like title and price, and extends this functionality to fetch detailed reviews from individual product pages. All the data is stored in an SQLite database for easy retrieval and analysis.

---

## Features

### Core Functionality
1. **Basic Product Data Retrieval**  
   Fetch product details like title, price, and product link based on a keyword search.
   
2. **Keyword-Based Search**  
   Dynamically search for products using user-provided keywords.

3. **Extended Product Details**  
   Retrieve additional product details (e.g., reviews) from the product's detail page.

4. **Product Links**  
   Save links to individual product pages for future reference.

5. **Database Integration**  
   Store all fetched product data in an SQLite database using the `Sequel` library.

---

## Requirements

To run this project, ensure you have the following installed:

- Ruby (I used version 3.4)
- SQLite
- Required Ruby Gems:
  - `nokogiri`
  - `open-uri`
  - `sequel`
  - `net/http`

___

## Usage

1. Run the program:
    ```
    ruby Main.rn
    ```

2. Enter the key word
    ```
    Enter a search word: laptop
    ```

3. View the results


