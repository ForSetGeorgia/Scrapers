require_relative 'environment'

# merge all of the csvs in the listings folder
# - prints out the number of total records and total pages scraped
# - create merged file
#   - only keep id columns (much smaller file size)
def merge_listings
  puts 'starting merge of listing csv files'
  start = Time.now
  merged = []
  files = Dir.glob("#{@listings_folder}/ww2_*.csv")

  if !files.nil?
    files.each do |file|
      # do not include headers
      merged << CSV.read(file)[1..-1]
    end
    merged = merged.flatten!(1)
    puts '- finished pulling out csv data'

    puts "- there are #{merged.length} records; #{merged.map{|x| x[2]}.uniq.length} unique ids ; and #{merged.map{|x| x[1]}.uniq.length} urls"

    puts "- starting to write out ids merged csv"
    CSV.open("#{@listings_folder}/merged_ids.csv", "wb") do |csv|
      # header
      csv << ['record id', 'record photo id']
      merged.each do |row|
        csv << row[2..3]
      end
    end
  end

  puts "TOTAL TIME TO MERGE = #{Time.now - start} seconds"
end

# use typheous to run several page downloads in parallel
# - this is the fast method - gets several pages at a time
def download_detail_html_pages_fast
  start = Time.now


  # get all ids
  all_ids = CSV.read("#{@listings_folder}/merged_ids.csv")[1..-1].map{|x| x[0]}

  # create folder if not exist
  FileUtils.mkdir_p @details_folder

  # get ids that have already been downloaded
  existing_files = Dir.glob("#{@details_folder}/*.html")
  remaining_ids = if existing_files.nil? || existing_files.length == 0
    all_ids
  else
    existing_files.map!{|x| x.split('/').last.gsub('.html', '')}

    # determine the remaining ids that need to be retrieved
    all_ids - existing_files
  end

  if remaining_ids.nil? || remaining_ids.length == 0
    puts "there are NO files to download"
  else
    puts "there are #{remaining_ids.length} files to download"

    #initiate hydra
    hydra = Typhoeus::Hydra.new(max_concurrency: 20)
    request = nil
    total_left_to_process = remaining_ids.length

    remaining_ids.each_with_index do |id, index|
      if index%50 == 0
        puts "#{index} files added to queue so far in #{((Time.now-start)/60).round(2)} minutes\n\n"
      end

      # request the url
      request = Typhoeus::Request.new("#{@details_url}#{id}", followlocation: true, ssl_verifypeer: false, ssl_verifyhost: 0)

      request.on_complete do |response|
        # save to file
        x = File.open("#{@details_folder}/#{id}.html", 'wb') { |file| file.write(response.response_body) }

        # decrease counter of items to process
        total_left_to_process -= 1
        if total_left_to_process == 0
          puts "TOTAL TIME TO DOWNLOAD = #{((Time.now-start)/60).round(2)} minutes"

        elsif total_left_to_process % 100 == 0
          puts "\n\n- #{total_left_to_process} files remain to download; time so far = #{((Time.now-start)/60).round(2)} minutes\n\n"
        end
      end
      hydra.queue(request)
    end

    hydra.run

  end
end

# use curl to download the html pages
# - this is the slow method - gets one page at a time
def download_detail_html_pages_slow
  start = Time.now

  # get all ids
  all_ids = CSV.read("#{@listings_folder}/merged_ids.csv")[1..-1].map{|x| x[0]}

  # create folder if not exist
  FileUtils.mkdir_p @details_folder

  # get ids that have already been downloaded
  existing_files = Dir.glob("#{@details_folder}/*.html")
  remaining_ids = if existing_files.nil? || existing_files.length == 0
    all_ids
  else
    existing_files.map!{|x| x.split('/').last.gsub('.html', '')}

    # determine the remaining ids that need to be retrieved
    all_ids - existing_files
  end

  if remaining_ids.nil? || remaining_ids.length == 0
    puts "there are NO files to download"
  else
    puts "there are #{remaining_ids.length} files to download"

    remaining_ids.each_with_index do |id, index|
      if index%50 == 0
        puts "\n\n- #{index} files downloaded so far in #{((Time.now-start)/60).round(2)} minutes\n\n"
      end

      `curl -o #{@details_folder}/#{id}.html #{@details_url}#{id}`
    end
  end

  puts "TOTAL TIME TO DOWNLOAD = #{Time.now - start} seconds"
end

# if the value exists, strip it and return it, else return nil
def process_value(value)
  if value.nil? || value.text.strip == ''
    nil
  else
    value.text.strip
  end
end

# pull the data out of the detail html pages
# and save to csv
def process_detail_html_pages
  start = Time.now

  # get all ids
  # - need this to get image id for image url
  all_ids = CSV.read("#{@listings_folder}/merged_ids.csv")[1..-1]

  # get list of html files
  html_files = Dir.glob("#{@details_folder}/*.html")
  remaining_files = []

  if html_files.nil? || html_files.length == 0
    puts "NO HTML FILES EXIST TO PROCESS!"
    exit
  end

  # get csv data, if not exist, create it
  if !File.exist?(@csv_data)
    CSV.open(@csv_data, 'wb') do |csv|
      # headers
      csv << @csv_headers
    end
  end
  csv_data = CSV.read(@csv_data)

  # if there is data that is already processed,
  # get the processed ids so we do process them again
  remaining_files = if csv_data.length > 0
    # first column is ids
    html_files - csv_data[1..-1].map{|x| "#{@details_folder}/#{x[0]}.html"}
  else
    html_files
  end

  # get rid of the csv data
  # - reduce memory load
  csv_data = nil

  # for each file
  # - open it in nokogiri
  # - pull out the data
  # - append to csv
  if remaining_files.length == 0
    puts "there are NO files to process"
  else
    puts "there are #{remaining_files.length} files to process"

    remaining_files.each_with_index do |file, index|
      row_data = []

      if index%50 == 0
        puts "#{index} files processed so far in #{((Time.now-start)/60).round(2)} minutes\n\n"
      end

      # open in nokogiri
      doc = File.open(file) { |f| Nokogiri::XML(f) }

      ###################
      # process the data
      # - id
      row_data << process_value(doc.css('#id_res'))

      # - last name
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Фамилия") + .card_param-result'))

      # - first name
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Имя") + .card_param-result'))

      # - middle name
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Отчество") + .card_param-result'))

      # - birth_date
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Дата рождения/Возраст") + .card_param-result'))

      # - place of birth
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Место рождения") + .card_param-result'))

      # - date/place of recruitment
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Дата и место призыва") + .card_param-result'))

      # - last place of service
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Последнее место службы") + .card_param-result'))

      # - military rank
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Воинское звание") + .card_param-result'))

      # - death reason
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Причина выбытия") + .card_param-result'))

      # - death date
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Дата выбытия") + .card_param-result'))

      # - initial burial location
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Первичное место захоронения") + .card_param-result'))

      # - source name
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Название источника донесения") + .card_param-result'))

      # - source fund number
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Номер фонда источника информации") + .card_param-result'))

      # - source description number
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Номер описи источника информации") + .card_param-result'))

      # - source file number
      row_data << process_value(doc.css('.card_parameter .card_param-title:contains("Номер дела источника информации") + .card_param-result'))

      # - source image url
      # - use the image id from the listings csv file to build the url
      record = all_ids.select{|x| x[0] == row_data[0]}.first
      if record.nil? || record[1].nil? || record[1] == ''
        row_data << nil
      else
        row_data << "#{@image_url}#{record[1]}"
      end


      ###################
      # append to the csv
      CSV.open(@csv_data, 'a') do |csv|
        csv << row_data
      end
    end
  end
end
