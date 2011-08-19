require 'rubygems'
require 'httparty'

class Rma
  include HTTParty
  #doesn't seem to pick up env variable correctly if I set it here
  #headers 'Authorization' => "OAuth #{ENV['sfdc_token']}"
  format :json
  # debug_output $stderr

  def self.set_headers
    headers 'Authorization' => "OAuth #{ENV['sfdc_token']}"
  end

  def self.root_url
    @root_url = ENV['sfdc_instance_url']+"/services/data/v"+ENV['sfdc_api_version']
  end

  def self.search(keyword)
    Rma.set_headers
    soql = "SELECT Id, Name, Items_Returned__c, Status__c, Sales_Order__r.Name from RMA__c Where Name = \'#{keyword}\'"
    get(Rma.root_url+"/query/?q=#{CGI::escape(soql)}")
  end
  
  def self.retrieve(id)
    Rma.set_headers
    get(Rma.root_url+"/sobjects/RMA__c/#{id}?fields=Id,Name") 
  end
  
end