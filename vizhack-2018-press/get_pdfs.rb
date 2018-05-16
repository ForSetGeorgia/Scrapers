# download the pdf files list in the merged spreadsheets

require 'csv'
require 'fileutils'

start = Time.now

# read in the data
merged = [
  'თეატრი და ცხოვრება - merged.csv',
  'ეშმაკის მათრახი - merged.csv',
  'სახალხო გვარდიელი - merged.csv',
  'ვაზი და ღვინო - merged.csv'
]

idx_pdf_url = 8

# create pdf directory
FileUtils::mkdir_p 'pdfs'

(0..merged.length-1).each do |i|
  puts "============"
  puts "working on #{merged[i]}"
  dir = "pdfs/#{merged[i].gsub(' - merged.csv', '')}"

  # create director if not exist
  FileUtils::mkdir_p dir

  data = CSV.read(merged[i])

  pdfs = data[1..-1].select{|x| !x.nil? && x.length > 0}.map{|x| x[idx_pdf_url]}.uniq
  puts "- #{pdfs.length} pdfs to download"

  # download the pdfs
  pdfs.each_with_index do |row, i|
    if i%5 == 0
      puts "\n\n\n\n*************\n- #{pdfs.length - 1 - i} records left\n-- #{((Time.now - start) / 60).round(2)} minutes so far\n\n\n\n"
    end

    # if the file does not exist, download it
    # - adding this in case the internet dies while downloading and have to restart
    if !row.nil? && row.length > 0
      filename = row.split('/').last
      puts "-- #{dir}/#{filename}; exists = #{File.exist?("#{dir}/#{filename}")}"
      if !File.exist?("#{dir}/#{filename}")
        # get the pdfs and save to the directory
        `wget -P '#{dir}' #{row}`
      end
    end
  end
end


puts "it took #{((Time.now - start) / 60).round(2)} minutes"

