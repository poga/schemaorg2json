require 'json'
require "nokogiri"

class Type
  attr_accessor :resource, :label, :comment, :parents, :properties
  def initialize
    @parents = []
    @properties = []
  end

  def to_json(options)
    return {resource: resource, label: label, comment: comment, parents: parents, properties: properties}.to_json
  end
end

class Property
  attr_accessor :resource, :label, :comment, :range
  def initialize
    @range = []
  end

  def to_json(options)
    return {resource: resource, label: label, comment: comment, range: range}.to_json
  end
end

result = {}
xml = Nokogiri::XML(File.read(ARGV[0]))
xml.xpath("//div[@typeof='rdfs:Class']").each do |class_node|
  type = Type.new
  type.resource = class_node.attributes["resource"].text
  class_node.traverse do |x|
    next unless x.attributes["property"]
    case x.attributes["property"].text
    when "rdfs:label"
      type.label = x.text.strip
    when "rdfs:comment"
      type.comment = x.text.strip
    when "rdfs:subClassOf"
      type.parents << x.attributes["href"].text
    end
  end
  result[type.resource] = type
end

xml.xpath("//div[@typeof='rdf:Property']").each do |property_node| # Property
  p = Property.new
  p.resource = property_node.attributes["resource"].text
  domains = []

  property_node.traverse do |x|
    next unless x.attributes["property"]
    case x.attributes["property"].text
    when "rdfs:label"
      p.label = x.text.strip
    when "rdfs:comment"
      p.comment = x.text.strip
    when "http://schema.org/domainIncludes"
      domains << x.attributes["href"].text
    when "http://schema.org/rangeIncludes"
      p.range << x.attributes["href"].text
    end
  end

  domains.each { |d| result[d].properties << p }
end

puts result.to_json
