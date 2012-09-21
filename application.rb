#!/usr/bin/env ruby

require 'karousel'
require 'rest_client'
require 'find'
require 'json'

class Page
  attr_accessor :status

  @@instances = []

  def self.populate(karousel_size)
    get_all_instances
    res = []
    karousel_size.times { res << @@instances.shift }
    res
  end

  def self.get_all_instances
    return unless @@instances.empty?
    files = Find.find('./bhl_sample').select {|i| i.match /\.txt$/}
    files.each do |f|
      @@instances << Page.new(f)
    end
  end

  def initialize(page_file)
    @file = page_file
    @status = 1
  end

  def send
    params = {:file => File.new(@file, 'r'), :unique => "true", :verbatim => "false", :detect_language => "false"}
    RestClient.post('http://128.128.175.111/name_finder.json', params) do |response, request, result, &block|
      if [302, 303].include? response.code
        @url = response.headers[:location]
        true
      else
        false
      end
    end
  end

  def finished?
    res = RestClient.get(@url)
    @names = JSON.parse(res, :symbolize_names => true)[:names]
  end

  def process
    puts @file
    puts @names
  end
end

k = Karousel.new(Page, 20, 5)
k.run  
