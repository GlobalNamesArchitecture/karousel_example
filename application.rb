#!/usr/bin/env ruby

require 'karousel'
require 'rest_client'
require 'find'
require 'json'

class Page < Karousel::ClientJob
  NAME_FINDER_URL = 'http://gnrd.globalnames.org/name_finder.json'
  attr_accessor :status

  @@instances = nil

  def self.populate(karousel_size)
    get_all_instances unless @@instances
    res = []
    karousel_size.times { res << @@instances.shift }
    res.compact
  end

  def self.get_all_instances
    @@instances = []
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
    RestClient.post(NAME_FINDER_URL, params) do |response, request, result, &block|
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
    puts "Items left: %s" % @@instances.size
  end
end

k = Karousel.new(Page, 20, 5)
k.run  
