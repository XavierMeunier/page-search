class ApiAdapter
  
  require 'rest_client'

  include ApplicationHelper
  
  # Function to Make Request
  def self.api_caller(method, url, content = {}, authentication = [], format_in = nil, timeout = 60, token = "")
    content = {} if content.nil?
    authentication = [] if authentication.nil?
    output = {
      "input_parameters" => {
        "method" => method,
        "url" => url,
        "content" => content,
        "auth" => authentication,
        "format_in" => format_in,
        "content_type" => nil,
        "timeout" => timeout,
        "token" => token
      },
      "content_request" => {},
      "response" => 1,
      "code" => 0,
      "message" => "beginning of the http request",
      "data" => {}
    }
    
    output = self.verif_params(output)
    if output["code"] == 0
      output["input_parameters"]["format_in"].nil? && output["input_parameters"]["method"] != "get" ? output["content_request"] = content : output = self.prepare_request(output)
      output = self.make_request(output)
      output = self.format_response(output)
      output["message"] = "Request done"
    end
    if !output["input_parameters"]["token"].blank?
      output["input_parameters"]["token"] = "*" * (token.length - 4) + token[-4..-1]
    else
      output["input_parameters"]["token"] = false
    end
    output
  end
  
  private
  
  # Verification of params before continue process
  def self.verif_params(output)
    url_regexp = /^https?:\/\/([a-zA-Z0-9éè-]{2,253}\.){1,4}([a-zA-z]){2,10}(([\/&?=])[a-zA-Z0-9éè\._\(\)%,=-]*)*$/
    
    if !output["input_parameters"]["format_in"].blank? && output["input_parameters"]["format_in"] != "json" && output["input_parameters"]["format_in"] != "xml"
      output["code"] = 20 
      output["message"] = "The format is not supported"
    elsif !output["input_parameters"]["auth"].blank? && output["input_parameters"]["auth"].length != 2
      output["code"] = 25
      output["message"] = "The authentication array should contain two element : user password"
    elsif !output["input_parameters"]["timeout"].blank? && !output["input_parameters"]["timeout"].is_a?(Integer)
      output["code"] = 30
      output["message"] = "The timeout should be an integer"
    elsif output["input_parameters"]["url"].blank? || !output["input_parameters"]["url"].match(url_regexp)
      output["code"] = 35
      output["message"] = "The url is invalid"
    elsif output["input_parameters"]["content"].blank? && output["input_parameters"]["method"] == :post
      output["code"] = 10
      output["message"] = "Content is missing for post request"
    elsif output["input_parameters"]["content"].blank? && output["input_parameters"]["method"] == :put
      output["code"] = 15
      output["message"] = "Content is missing for put request"
    elsif !output["input_parameters"]["content"].blank? && !output["input_parameters"]["content"].is_a?(Hash)
      output["code"] = 45
      output["message"] = "The content params must be an hash"
    elsif ![:put, :get, :post, :delete].include? output["input_parameters"]["method"]
      output["code"] = 40
      output["message"] = "The method string is invalid, use : put, get, post, delete"
    else
      output["message"] = "Params Ok"
    end
    output
  end

  # Format Data to send in request
  def self.prepare_request(output)
    !output["input_parameters"]["content"].blank? && output["input_parameters"]["content"].is_a?(Hash) ? content = output["input_parameters"]["content"].deep_symbolize_keys : content = output["input_parameters"]["content"]
    format_in = output["input_parameters"]["format_in"]
    output["data"] = {}

    if output["input_parameters"]["method"] == "get" && !output["input_parameters"]["content"].blank?
      url = ""
      output["input_parameters"]["content"].each_with_index do |arg, index|
        index == 0 ? url += "?" : url += "&"
        url += "#{arg.first}=#{arg.last}"
      end
      output["input_parameters"]["url"] += URI::encode(url)
    end
    
    if format_in == "json"
      content = content.to_json if !content.blank? && content.is_a?(Hash)
      output["input_parameters"]["content_type"] = "application/json"
      output["message"] = "Data has been prepared to send json"
    elsif format_in == "xml"
      content = content.to_xml if !content.blank? && content.is_a?(Hash)
      output["input_parameters"]["content_type"] = "application/xml"
      output["message"] = "Data has been prepared to send xml"
    else
      output["message"] = "Wrong data format_in, data has not been prepared"
    end
    output["content_request"] = content
    output
  end

  # Make HTTP Request
  def self.make_request(output)    
    request = RestClient::Request.new(
        :method => output["input_parameters"]["method"].to_sym,
        :url => output["input_parameters"]["url"],
        :operation_timeout => output["input_parameters"]["timeout"],
        :content_type => output["input_parameters"]["content_type"],
        :user => output["input_parameters"]["auth"][0],
        :password => output["input_parameters"]["auth"][1],
        :payload => output["content_request"],
        :headers => {
          :authorization => output["input_parameters"]["token"],
          :accept_encoding => "*",
          :accept_charset => "UTF-8",
          :accept => "*/*"
        }
    )
        
    begin
      feedback = request.execute
      output["response"] = 0
      output["code"] = feedback.code
      output["message"] = "Successfull request"
      output["data"] = feedback
      feedback
    rescue => e
      output["code"] = e.response.code
      output["message"] = e.response
      output["data"] = {}
    end
    
    output
  end


  # Format received response into hash
  def self.format_response(output)
    if !output["data"].blank? && ApplicationHelper.valid_json?(output["data"])
      data = JSON.parse(output["data"])
      output["message"] = "Data has been parsed from json"
    elsif !output["data"].blank? && ApplicationHelper.valid_xml?(output["data"])
      data = Hash.from_xml(output["data"])
      data = data.symbolize_keys
      data = data[:hash] if !data[:hash].blank?
      output["message"] = "Data has been parsed from xml"
    else
      data = output["data"]
      output["message"] = "Data has not been parsed"
    end
    !data.blank? && data.is_a?(Hash) ? output["data"] = data.deep_symbolize_keys : output["data"] = data
    output
  end
    
end