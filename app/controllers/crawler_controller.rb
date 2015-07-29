class CrawlerController < ApplicationController
  before_action :reset_worker, only: [:index, :thieving]

  def index
    @jobs = Job.all
    @companies = Company.all
  end

  def thieving
    # workpage = get_work_page_doda
    # page_count = workpage.search("div.number_list ul li")[-3].text.to_i

    # worker_num = Settings.number_worker
    # if page_count % worker_num == 0
    #   page_per_job = page_count / worker_num
    # else
    #   page_per_job = page_count / worker_num + 1
    # end
    
    # worker_num.times do |i|
    #   start_page = page_per_job * i + 1
    #   finish_page = page_per_job * (i + 1)
    #   byebug
    #   DodaWorker.perform_async start_page, finish_page
    # end

    # DodaWorker.perform_async 1, 1

    link = "http://doda.jp/DodaFront/View/JobSearchDetail/j_jid__3001015054/-tab__jd/-fm__jobdetail/-mpsc_sid__10/-tp__1/"

    companies_hash = {}

    detail_page = mechanize_webstie link

    raw_full_address = parse_left_block detail_page
    companies_hash[:raw_address] = raw_full_address

    regx12 = Settings.regular.address.address1and2

    if raw_full_address.present?
      full_address = parse_full_address raw_full_address
      companies_hash[:full_address] = full_address
      
      if regx12.match(full_address).present?
        if regx12.match(full_address)[1].present?
          raw_postal_code = regx12.match(full_address)[1].to_s.strip
          companies_hash[:postal_code] = parse_postal_code raw_postal_code
        end
      end
    end

    redirect_to root_path
  end

  def export
    @jobs = Job.all
    @companies = Company.all
    respond_to do |format|
      format.xlsx do
        send_data ExportRubyxl.export_file @jobs, @companies
      end
    end
  end
end
