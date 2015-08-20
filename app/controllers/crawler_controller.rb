class CrawlerController < ApplicationController
  before_action :reset_worker, only: [:index, :thieving]
  before_action :reset_error_log, only: :thieving

  def index
    @jobs = Job.all
    @companies = Company.all
  end

  def thieving
    if params[:source] == ["green"]
      page_count = get_number_page_green
    elsif params[:source] == ["doda"]
      page_count = get_number_page_doda
    elsif params[:source] == ["ecareer"]
      page = get_number_page_ecareer
      page_count = page[1]
    elsif params[:source] == ["jsen"]
      page_count = get_number_page_jsen
    end
      

    worker_num = Settings.number_worker
    # if page_count % worker_num == 0
    #   page_per_job = page_count / worker_num
    # else
    #   page_per_job = page_count / worker_num + 1
    # end
    page_num = Settings.page_per_job
    Settings.number_worker.times do |i|
      start_page = page_num * i + 1
      finish_page = page_num * (i + 1)
      if params[:source] == ["green"]
        GreenWorker.perform_async start_page, finish_page
      elsif params[:source] == ["doda"]
        DodaWorker.perform_async start_page, finish_page
      elsif params[:source] == ["ecareer"]
        EcareerWorker.perform_async page, start_page, finish_page
      elsif params[:source] == ["jsen"]
        JsenWorker.perform_async start_page, finish_page
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
