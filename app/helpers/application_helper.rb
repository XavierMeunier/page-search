module ApplicationHelper

  def self.valid_json?(json_)
    begin
      json_ = json_.to_s
      JSON.parse(json_)
      return true
    rescue JSON::ParserError
      return false
    end
  end

  def self.valid_xml?(xml_)
    begin
      Hash.from_xml(xml_)
      return true
    rescue
      return false
    end
  end

end
