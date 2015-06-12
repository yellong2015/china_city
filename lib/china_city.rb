# encoding: utf-8
require "china_city/engine"

module ChinaCity
  CHINA = '000000' # 全国
  PATTERN = /(\d{2})(\d{2})(\d{2})/

  class << self
    def html_options(parent_id = '000000')
      list(parent_id).map{|item| [item[0], item[0], {'data-value' => item[1] }] }
    end
    
    def list(parent_id = '000000')
      result = []
      return result if parent_id.blank?
      province_id = province(parent_id)
      city_id = city(parent_id)
      district_id = district(parent_id)
      children = data
      children = children[province_id][:children] if children.has_key?(province_id)
      children = children[city_id][:children] if children.has_key?(city_id)
      children = children[district_id][:children] if children.has_key?(district_id)
      children.each_key do |id|
        result.push [ children[id][:text], id]
      end

      #sort
      result.sort! {|a, b| a[1] <=> b[1]}
    end

    # @options[:prepend_parent] 是否显示上级区域
    def get(id, options = {})
      return '' if id.blank?
      prepend_parent = options[:prepend_parent] || false
      children = data
      return children[id][:text] if children.has_key?(id)
      province_id = province(id)
      province_text = children[province_id][:text]
      children = children[province_id][:children]
      return "#{prepend_parent ? province_text : ''}#{children[id][:text]}" if children.has_key?(id)
      city_id = city(id)
      city_text = children[city_id][:text]
      children = children[city_id][:children]
      return "#{prepend_parent ? (province_text + city_text) : ''}#{children[id][:text]}"
    end

    def province(code)
      match(code)[1].ljust(6, '0')
    rescue => e
      p e.to_s, 'code', code
      raise e.to_s
    end

    def city(code)
      id_match = match(code)
      "#{id_match[1]}#{id_match[2]}".ljust(6, '0')
    end

    def district(code)
      code[0..5].rjust(6,'0')
    end

    def get_id(type=:state, code)
      ret = origin_data[type.to_s].select{|i| i['text'] == code}
    end

    private

    def origin_data
      @origin_data ||= JSON.parse(File.read("#{Engine.root}/db/china_city_areas_2015.06.12.json"))
    end

    def data
      unless @list
        #{ '440000' =>
        #  {
        #    :text => '广东',
        #    :children =>
        #      {
        #        '440300' =>
        #          {
        #            :text => '深圳',
        #            :children =>
        #              {
        #                '440305' => { :text => '南山' }
        #              }
        #           }
        #       }
        #   }
        # }
        @list = {}
        #@see: http://github.com/RobinQu/LocationSelect-Plugin/raw/master/areas_1.0.json
        json = origin_data
        # json = JSON.parse(File.read("#{Engine.root}/db/areas.json"))

        streets = json.values.flatten
        p streets.size
        streets.each do |street|
          id = street['id']
          text = street['text']
          next if id.nil? || id.size < 6
          if id.end_with?('0000')
            @list[id] =  {:text => text, :children => {}}
          elsif id.end_with?('00') && id.size == 6
            province_id = province(id)
            @list[province_id] = {:text => nil, :children => {}} unless @list.has_key?(province_id)
            @list[province_id][:children][id] = {:text => text, :children => {}}
          elsif id.size == 6
            province_id = province(id)
            city_id = city(id)
            @list[province_id] = {:text => text, :children => {}} unless @list.has_key?(province_id)
            @list[province_id][:children][city_id] = {:text => text, :children => {}} unless @list[province_id][:children].has_key?(city_id)
            @list[province_id][:children][city_id][:children][id] = {:text => text, :children => {}}
          else
            province_id = province(id)
            city_id = city(id)
            district_id = district(id)
            @list[province_id] = {:text => text, :children => {}} unless @list.has_key?(province_id)
            @list[province_id][:children][city_id] = {:text => text, :children => {}} unless @list[province_id][:children].has_key?(city_id)
            @list[province_id][:children][city_id][:children][district_id] = {:text => text, :children => {}} unless @list[province_id][:children][city_id][:children].has_key?(district_id)
            @list[province_id][:children][city_id][:children][district_id][:children][id] = {:text => text}
          end
        end
      end
      @list
    end

    def match(code)
      code.match(PATTERN)
    end
  end
end