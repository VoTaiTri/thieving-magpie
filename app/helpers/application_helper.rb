module ApplicationHelper
  require "sidekiq/api"
  require "mechanize"

  def mechanize_webstie web_url
    agent = Mechanize.new
    agent.user_agent_alias = "Mac Safari"
    agent.get web_url
  end

  def reset_worker
    Sidekiq::Queue.new.clear
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
    # Sidekiq::Workers.new
  end

  def convert_new_line objects
    objects.each do |object|
      if object.name == "br" || object.name == "p"
        object.content = "\n"
      end
      if Nokogiri::XML::Text == object.class
        object.content = object.text.squish
      end
    end
  end

  def remove_space_in_text str
    str.delete(" ")
  end

  def parse_postal_code str
    raw = str.scan(/〒?([０-９0-9[-－‐]{1}]{8}\s?)/).join("/").squish
    raw_postal_code = remove_space_in_text raw
    raw_postal_code.delete("^0-9０-９/")
  end

  def parse_tel_number full_tel
    raw_tel = ""
    if /[FＦ]\s?[AＡ]\s?[XＸ]/i.match(full_tel).present? || /ファクシミリ/.match(full_tel).present?
      if /[ＴＥＬTELtel電話]+\D*([[0-9０-９]+[-\(][0-9０-９]+[-\)][0-9０-９]+]{9,13})+/i.match(full_tel).present?
        raw_tel = full_tel.scan(/[ＴＥＬTELtel電話]+\D*([[0-9０-９]+[-\(][0-9０-９]+[-\)][0-9０-９]+]{9,13})+/i).join("/")
      elsif /([[0０]([0-9０-９]+[-－]?[0-9０-９]+[-－]?[0-9０-９]+)]{9,13})+\s*[\(（]\s*[TＴ]\s?[EＥ]\s?[LＬ]/i.match(full_tel).present?
        raw_tel = full_tel.scan(/([[0０]([0-9０-９]+[-－]?[0-9０-９]+[-－]?[0-9０-９]+)]{9,13})+\s*[\(（]\s*[TＴ]\s?[EＥ]\s?[LＬ]/i).join("/")
      end
    else
      if /([0０][([0-9０-９]+[-－‐\(（]?[0-9０-９]+[-－‐\)）]?[0-9０-９]+)]{8,12})/.match(full_tel).present?
        raw_tel = full_tel.scan(/([0０][([0-9０-９]+[-－‐\(（]?[0-9０-９]+[-－‐\)）]?[0-9０-９]+)]{8,12})/).join("/")
      end
    end
    tel = raw_tel.delete("^0-9０-９/")
  end

  def parse_address34 full_address
    regx = Settings.regular.address.address1and2
    regx1 = Settings.regular.address.address4.end_string
    regx2 = Settings.regular.address.address4.bracket
    regx34 = Settings.regular.address.address3and4
    regx34ex = Settings.regular.address.address34exception

    address34 = ""
    address3 = ""
    address4 = ""
    if regx.match(full_address)[4].present?
      address34 = regx.match(full_address)[4].to_s.strip
      if regx34ex.match(address34).present?
        address3 = regx34ex.match(address34)[1].to_s.squish if regx34ex.match(address34)[1].present?
        address4 = regx34ex.match(address34)[2].to_s.squish if regx34ex.match(address34)[2].present?
      elsif regx34.match(address34).present?
        address3 = regx34.match(address34)[1].to_s.squish if regx34.match(address34)[1].present?
        if regx34.match(address34)[3].present?
          raw_address4 = regx34.match(address34)[3].to_s.strip
          if regx1.match(raw_address4).present? && regx1.match(raw_address4)[1].present?
            address4 = regx1.match(raw_address4)[1].to_s.squish
          elsif regx2.match(raw_address4).present?
            if regx2.match(raw_address4)[1].blank? && regx2.match(raw_address4)[2].present? && regx2.match(raw_address4)[3].blank?
              address4 = regx2.match(raw_address4)[2].to_s.squish
            elsif regx2.match(raw_address4)[1].present?
              address4 = raw_address4.to_s.squish
            end
          else
            address4 = raw_address4.squish
          end
        end
      end
    end
    raw_address34 = [address34, address3, address4]
  end

  def parse_address34_exception full_address, regx_value
    regx = Settings.regular.address.address1and2
    regx1 = Settings.regular.address.address4.end_string
    regx2 = Settings.regular.address.address4.bracket
    regx34 = Settings.regular.address.address3and4
    regx34ex = Settings.regular.address.address34exception
    
    address34 = ""
    address3 = ""
    address4 = ""
    if regx.match(full_address)[4].present?
      raw_address34 = regx.match(full_address)[4].to_s.strip
      if regx_value.match(raw_address34).present? && regx_value.match(raw_address34)[1].present?
        address34 = regx_value.match(raw_address34)[1].to_s.strip 
      else
        address34 = raw_address34
      end
      if regx34ex.match(address34).present?
        address3 = regx34ex.match(address34)[1].to_s.squish if regx34ex.match(address34)[1].present?
        address4 = regx34ex.match(address34)[2].to_s.squish if regx34ex.match(address34)[2].present?
      elsif regx34.match(address34).present?
        address3 = regx34.match(address34)[1].to_s.squish if regx34.match(address34)[1].present?
        if regx34.match(address34)[3].present?
          raw_address4 = regx34.match(address34)[3].to_s.strip
          address4 = address3and4(full_address)[2].to_s.squish
        end
      end
    end
    raw_address34 = [address34, address3, address4]
  end
end
