class CrawlerController < ApplicationController
  before_action :reset_worker, only: [:index, :thieving]
  before_action :reset_error_log, only: :thieving
  config.relative_url_root = ""

  def index
    @jobs = Job.all
    @companies = Company.all
    @reference_company = Company.with_reference
  end

  def thieving
    if params[:source] == ["green"]
      page_count = get_number_page_green
    elsif params[:source] == ["doda"]
      page_count = get_number_page_doda
    elsif params[:source] == ["ecareer"]
      page_count = get_number_page_ecareer
    elsif params[:source] == ["jsen"]
      page_count = get_number_page_jsen
    end

    
    worker_num = Settings.number_worker
    page = page_count / worker_num
    page_per_job = page_count % worker_num == 0? page : page + 1
    # page_per_job = Settings.page_per_job
    worker_num.times do |i|
      start_page = page_per_job * i + 1
      finish_page = page_per_job * (i + 1)
      time_sleep = (i + 1) * 0.5
      sleep time_sleep
      if params[:source] == ["green"]
        GreenWorker.perform_async start_page, finish_page
      elsif params[:source] == ["doda"]
        DodaWorker.perform_async start_page, finish_page
      elsif params[:source] == ["ecareer"]
        EcareerWorker.perform_async page_count, start_page, finish_page
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

  def import
    file_upload = params[:company_file]

    File.open(Rails.root.join('public', 'uploads', file_upload.original_filename), 'wb') do |file|
      file.write(file_upload.read)
    end

    file_path = Settings.download_path + file_upload.original_filename
    
    ImportRubyxl::check_reference_company file_path

    File.delete file_path

    redirect_to root_path
  end
end
