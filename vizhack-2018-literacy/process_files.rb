# pull in all data from the original_data folder, clean it, and merge into one spreadsheet

require 'csv'

start = Time.now

all_data = []
data_files = Dir.glob('original_data/*.csv')

idx_cols_to_add = [
  10,20,21
]
idx_cols_to_remove = [
  0,1,2,3,4,16,17,18,19,20
]
idx_image = 7
idx_death = 9
idx_age = 10
idx_org = 14 #13 + 1
idx_awards = 15 #14 + 1
idx_address = 17 #16 + 1
idx_job = 19 # 18 + 1
idx_new_address = 21
idx_new_job = 22

csv_headers = [
  "url",
  "name",
  "image",
  "birth",
  "death",
  "age",
  "place burried",
  "category",
  "biography",
  "organization/association/group",
  "awards/bonuses/prizes",
  "address",
  "job"
]


data_files.each do |file|
  puts "----------"
  puts file

  data = CSV.read(file)

  # add the new columns
  puts "- adding new columns"
  data.each do |data_item|
    idx_cols_to_add.reverse.each do |idx|
      data_item.insert(idx, nil)
    end
  end

  puts "- cleaning data"
  data.each_with_index do |data_item, j|
    # first row is header - skip it
    if j > 0
      # make image path a full url
      # if the image is noimage, remove it
      data_item[idx_image] = data_item[idx_image] == 'themes/bios/images/nophoto0n.jpg' ? nil : "http://www.nplg.gov.ge/ilia/#{data_item[idx_image]}"


      # pull age out of death
      # - it is in end of death, so split death and age
      if data_item[idx_death] != 'null'
        regexp_match = /^(.*)  \((\d+).*\)$/.match(data_item[idx_death])
        if !regexp_match.nil?
          data_item[idx_death] = regexp_match[1]
          data_item[idx_age] = regexp_match[2]
        end
      end

      # remove li tags in org and awards
      # - li tags were left in so it would be possible
      #   to see where each item started and stopped
      data_item[idx_org] = data_item[idx_org].gsub('<li>', '').gsub('</li>', '')
      data_item[idx_awards] = data_item[idx_awards].gsub('<li>', '').gsub('</li>', '')

      # merge address
      # - addresses are shown in different formats
      #   so had to create two different fields to record them
      address1 = data_item[idx_address]
      address2 = data_item[idx_address+1]
      data_item[idx_new_address] = address1 != 'null' ? address1 : address2 != 'null' ? address2 : nil

      # merge job
      # - jobs are shown in different formats
      #   so had to create two different fields to record them
      job1 = data_item[idx_job]
      job2 = data_item[idx_job+1]
      data_item[idx_new_job] = job1 != 'null' ? job1 : job2 != 'null' ? job2 : nil
      # it is possible that the job text is the same as the address text
      # if it is, delete it
      data_item[idx_new_job] = !data_item[idx_new_job].nil? && data_item[idx_new_job] == data_item[idx_new_address] ? nil : data_item[idx_new_job]


      # remove the unwanted columns
      idx_cols_to_remove.reverse.each do |idx|
        data_item.delete_at(idx)
      end

      # clean up the text
      # - remove null
      # - remove any extra spaces
      (0..data_item.length-1).each do |idx_col|
        if data_item[idx_col].class == String
          data_item[idx_col] = data_item[idx_col] == 'null' ? nil : data_item[idx_col].chomp.strip
        end
      end

    end
  end

  # append the data to all other data
  # do not add the headers
  puts "- adding to all data"
  all_data << data[1..-1]
end

all_data.flatten!(1)

# write out csv
puts "=========="
puts "- creating file"
CSV.open('ilia_merged_clean.csv', "wb") do |csv|
  # headers
  csv << csv_headers

  # data
  all_data.each do |data_item|
    csv << data_item
  end
end




puts "it took #{Time.now - start} seconds"

