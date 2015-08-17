class CrawlerController < ApplicationController
  before_action :reset_worker, only: [:index, :thieving]
  before_action :reset_error_log, only: :thieving

  def index
    @jobs = Job.all
    @companies = Company.all
  end

  def thieving
    if params[:source] == ["doda"]
      # workpage = get_work_page_doda
      # page_count = workpage.search("div.number_list ul li")[-3].text.to_i

      # worker_num = Settings.number_worker
      # if page_count % worker_num == 0
      #   page_per_job = page_count / worker_num
      # else
      #   page_per_job = page_count / worker_num + 1
      # end
      page_num = Settings.page_per_job
      Settings.number_worker.times do |i|
        start_page = page_num * i + 1
        finish_page = page_num * (i + 1)
        # byebug
        DodaWorker.perform_async start_page, finish_page
      end
    elsif params[:source] == ["ecareer"]
      byebug
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
