module ApplicationHelper
  require "sidekiq/api"
  require "mechanize"
  require "open-uri"
  require "selenium-webdriver"

  def mechanize_website web_url
    agent = Mechanize.new
    agent.user_agent_alias = "Mac Safari"
    agent.get web_url
  end

  def get_page_by_first_form url
    page = mechanize_website url
    form = page.forms.first
    button = form.buttons.first
    form.submit button
  end

  def get_page_by_link_text url, text
    page = mechanize_website url
    page = page.link_with(text: text).click
  end

  def reset_worker
    Sidekiq::Queue.new.clear
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
    # Sidekiq::Workers.new
  end

  def convert_new_line objects
    objects.each do |object|
      object.content = "\n" if object.name == "br"
      object.content = object.text.strip + "\n" if object.name == "p"
      object.content = object.text.strip if Nokogiri::XML::Text == object.class
    end
  end

  def reset_error_log
    file = File.open("thieving_error_log", "w")
    file.write("")
  end

  def write_error_to_file error, count, text
    file = File.open("thieving_error_log", "a+")
    file.write("#{error} error #{count}: " + " #{text}!\n")
  end

  def handle_general_text str
    if str.present?
      str = str.delete Settings.space
      str = str.han_to_zen
      converter = Itaiji::Converter.new
      str = converter.convert_seijitai str
    end
    str
  end

  def convert_company_name str
    if str.present?
      str = str.delete Settings.strange
      str = str.mb_chars.upcase.to_s
      str = str.katakana

      str = str.gsub /(（株）|㈱)/, "株式会社"
      str = str.gsub /(（有）|㈲)/, "有限会社"

      while /([\(【『「（≪＜]{1}[^\(\)【】『』「」（）≪≫＜＞]*[\)】』」）≫＞]{1})/.match(str).present?
        raw_str = ""
        arr = str.scan /([\(【『「（≪＜]{1}[^\(\)【】『』「」（）≪≫＜＞]*[\)】』」）≫＞]{1})/
        arr.each do |a|
          if /([^／：・]*[／：・]*)/.match(a[0]).present?
            sub = /([^\(\)【】『』「」（）≪≫＜＞]+)/.match(a[0])[1]
            arr1 = sub.scan /([^／：・]*[／：・]*)/
            arr1.each do |a1|
              if /有限会社|株式会社/.match(a1[0]).nil?
                sub.gsub! a1[0], ""
              end
            end
            sub = sub.delete "／：・\(\)【】『』「」（）≪≫＜＞"
            str = str.gsub a[0], sub
          elsif /有限会社|株式会社/.match(a[0]).nil?
            str = str.gsub a[0], ""
          elsif /有限会社|株式会社/.match(a[0]).present?
            sub = a[0].delete "／：・\(\)【】『』「」（）≪≫＜＞"
            str = str.gsub a[0], sub
          end
        end
      end

      if /[／：・]/.match(str).present? && /([^／：・]*[／：・]*)/.match(str).present? 
        sub = []
        dem = 0
        arr = str.scan /([^／：・]*[／：・]*)/
        arr.each do |a|
          if /有限会社|株式会社/.match(a[0]).present?
            sub[dem] = a[0].delete "／：・"
            dem += 1
          end
        end
        str = sub.join
      end
    end
    str
  end

  def parse_full_address raw_address
    full_address = ""
    if Settings.regular.address.multiple.e.match(raw_address).present? && Settings.regular.address.multiple.e.match(raw_address)[1].present?
      full_address = Settings.regular.address.multiple.e.match(raw_address)[1].to_s.strip
    elsif Settings.regular.address.multiple.b.match(raw_address).present? && Settings.regular.address.multiple.b.match(raw_address)[1].present?
      full_address = Settings.regular.address.multiple.b.match(raw_address)[1].to_s.strip
    elsif /^.+：(.*)\/.*：/.match(raw_address).present?
      full_address = /^.+：(.*)\/.*：/.match(raw_address)[1].to_s.strip if /^.+：(.*)\/.*：/.match(raw_address)[1].present?
    else
      full_address = raw_address
    end
    return full_address
  end

  def parse_final_address full_address
    final_address = ["", "", "", "", "", ""]
    regx12 = Settings.regular.address.address1and2

    if regx12.match(full_address).present?
      if regx12.match(full_address)[1].present?
        raw_postal_code = regx12.match(full_address)[1].to_s.strip
        final_address[0] = parse_postal_code raw_postal_code
      end
    
      if regx12.match(full_address)[2].present?
        raw_address1 = regx12.match(full_address)[2].to_s.strip
        if /^.*?([】\\／＞：])(.*)$/.match(raw_address1).present?
          address1 = /^.*?([】\\／＞：])(.*)$/.match(raw_address1)[2].to_s.squish if /^.*?([】\\／＞：])(.*)$/.match(raw_address1)[2].present?
          charactor = /^.*?([】\\／＞：])(.*)$/.match(raw_address1)[1].to_s if /^.*?([】\\／＞：])(.*)$/.match(raw_address1)[1].present?
          if /[：]/.match(charactor).present?
            raw_address34 = parse_address34_exception(full_address, /(.*)\s.*：/)
          elsif /[】\]＞／]/.match(charactor).present?
            raw_address34 = parse_address34_exception(full_address, /(.*)[【\[＜／]/)
          else
            raw_address34 = parse_address34 full_address
          end
        else
          address1 = raw_address1.squish
          raw_address34 = parse_address34 full_address
        end
        final_address[1] = address1
      else
        raw_address34 = parse_address34 full_address
      end

      if regx12.match(full_address)[3].present?
        raw_address2 = regx12.match(full_address)[3].to_s.strip
        if /^.*?([】\\／＞：])(.*)$/.match(raw_address2).present? && regx12.match(full_address)[2].blank?
          address2 = /^.*?([】\\／＞：])(.*)$/.match(raw_address2)[3].to_s.squish if /^.*?([】\\／＞：])(.*)$/.match(raw_address2)[3].present?
          charactor = /^.*?([】\\／＞：])(.*)$/.match(raw_address2)[1].to_s if /^.*?([】\\／＞：])(.*)$/.match(raw_address2)[1].present?
          if /[：]/.match(charactor).present?
            raw_address34 = parse_address34_exception(full_address, /(.*)\s.*：/)
          elsif /[】\]＞]/.match(charactor).present?
            raw_address34 = parse_address34_exception(full_address, /(.*)[【\[＜]/)
          end
        else
          address2 = raw_address2.squish
        end
        final_address[2] = address2
      end

      final_address[3] = handle_general_text raw_address34[0]
      address3 = handle_general_text raw_address34[1]
      address4 = handle_general_text raw_address34[2]
      final_address[4] = address3.gsub "－", "−"
      final_address[5] = convert_floor address4
    end
    final_address
  end

  def parse_postal_code str
    if str.present?
      raw_postal_code = str.scan(/〒?([０-９0-9[-－‐]{1}]{8}\s?)/).join("/")
      str = raw_postal_code.delete("^0-9０-９/")
    end
    str
  end

  def parse_tel_number full_tel
    raw_tel = ""
    if /Ｆ\s?Ａ\s?Ｘ\s?/i.match(full_tel).present? || /ファクシミリ/.match(full_tel).present?
      if /[ＴＥＬ電話]+\D*([[０-９]+[-\(][０-９]+[-\)][０-９]+]{9,13})+/i.match(full_tel).present?
        raw_tel = full_tel.scan(/[ＴＥＬ電話]+\D*([[０-９]+[-\(][０-９]+[-\)][０-９]+]{9,13})+/i).join("／")
      elsif /([[０]([０-９]+[-－]?[０-９]+[-－]?[０-９]+)]{9,13})+\s*[\(（]\s*[Ｔ]\s?[Ｅ]\s?[Ｌ]/i.match(full_tel).present?
        raw_tel = full_tel.scan(/([[０]([０-９]+[-－]?[０-９]+[-－]?[０-９]+)]{9,13})+\s*[\(（]\s*[Ｔ]\s?[Ｅ]\s?[Ｌ]/i).join("／")
      end
    else
      if /([０][([０-９]+[-－‐\(（]?[０-９]+[-－‐\)）]?[０-９]+)]{8,12})/.match(full_tel).present?
        raw_tel = full_tel.scan(/([0０][([０-９]+[-－‐\(（]?[０-９]+[-－‐\)）]?[０-９]+)]{8,12})/).join("／")
      end
    end
    raw_tel.delete "^０-９／"
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
    [address34, address3, address4]
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
          address4 = parse_address34(full_address)[2].to_s.squish
        end
      end
    end
    [address34, address3, address4]
  end

  def convert_floor str
    if str.present?
      str.gsub "階", "Ｆ"
    end
    str
  end

  def convert_home_page url
    if url.present?
      url = url.gsub(/／$/, "").gsub("ｗｗｗ．", "")
      if Settings.regular.home_page.match(url).present?
        url = url.gsub Settings.regular.home_page, ""
      end
    end
    url
  end

  def check_existed_company hash
    mark = []
    dup = []
    if hash[:convert_name].present? && Company.exists?(convert_name: hash[:convert_name])
      companies = Company.where convert_name: hash[:convert_name] 
      companies.each_with_index do |company, num|
        mark[num] = 2
        mark[num] += check_duplicate_home_page company, hash[:home_page] # 2/0.5
        mark[num] += check_duplicate_tel company, hash[:tel] # 0.5/1/1.5 
        mark[num] += check_duplicate_address(company, hash[:address1],
                              hash[:address2], hash[:address3], hash[:address4]) # 0.5/1/1.5/2
        if mark[num] >= 4
          dup = [mark[num], company.id]
        end
      end
    elsif hash[:home_page].present? && Company.exists?(home_page: hash[:home_page])
      companies = Company.where home_page: hash[:home_page]
      companies.each_with_index do |company, num|
        mark[num] = 2
        mark[num] += check_duplicate_tel company, hash[:tel] # 0.5/1/1.5
        mark[num] += check_duplicate_address(company, hash[:address1], 
                              hash[:address2], hash[:address3], hash[:address4]) # 0.5/1/1.5/2

        if mark[num] >= 3
          dup = [mark[num], company.id]
        end
      end
    end
    dup
  end


  def check_duplicate_address company, address1, address2, address3, address4
    mark = 0
    if company.address1 == address1
      mark += 0.5
      if company.address2 == address2
        mark += 0.5
        if company.address3 == address3
          mark += 0.5
          if company.address4 == address4
            mark += 0.5
          end
        end
      end
    end
    mark
  end

  def check_duplicate_home_page company, home_page
    mark = 0
    if home_page.blank? && home_page == company.home_page
      mark += 0.5
    elsif home_page.present? && home_page == company.home_page
      mark += 2
    end
    mark
  end

  def check_duplicate_tel company, phone
    mark = 0
    if phone.blank? && phone == company.tel
      mark += 0.5
    elsif phone.present?
      dem = 0
      phones_array = phone.split("／")
      phones_array.each do |t|
        if company.tel.present? && company.tel.include?(t)
          dem += 1
        end
      end
      if 3 * dem < 2 * phones_array.count
        mark += 1
      else
        mark += 1.5
      end
    end
    mark
  end

  def get_business_category_for_company company, job_business_category
    if company.business_category.present?
      raw_business_category = company.business_category + "," + job_business_category
    else
      raw_business_category = job_business_category
    end
    raw_business_category.split(",").uniq.join(",")
  end
end
