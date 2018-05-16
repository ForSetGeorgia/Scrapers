# pull in each set of csv files, merge them into one and write out a new one

require 'csv'

start = Time.now

# read in the data
issues = [
  'თეატრი და ცხოვრება - issues.csv',
  'ეშმაკის მათრახი - issues.csv',
  'სახალხო გვარდიელი - issues.csv',
  'ვაზი და ღვინო - issues.csv'
]
articles = [
  'თეატრი და ცხოვრება - articles.csv',
  'ეშმაკის მათრახი - articles.csv',
  'სახალხო გვარდიელი - articles.csv',
  'ვაზი და ღვინო - articles.csv'
]
merged = [
  'თეატრი და ცხოვრება - merged.csv',
  'ეშმაკის მათრახი - merged.csv',
  'სახალხო გვარდიელი - merged.csv',
  'ვაზი და ღვინო - merged.csv'
]

pdf_url = 'https://press.vizhack.ge/pdfs/'
idx_issue_num = 3
idx_issue_year = 5
idx_article_num = 8
idx_article_year = 7
idx_description = 16
idx_issue_pdf_name = 8
issue_col_count = 12
idx_cols_to_remove = [
  0,5,11,12,14,15
]

csv_headers = [
  'issue url',
  'issue title',
  'issue number',
  'issue date',
  'issue publisher',
  'issue description',
  'issue owner',
  'issue collection',
  'issue pdf url',
  'article url',
  'article publication',
  'article title',
  'article authors',
  'article year',
  'article issue number',
  'article page number',
  'article description',
  'article MFN',
  'article ანოტაცია',
  'article გეოგ დასახელება',
  'article თემატიკა',
  'article მოხსენიებული პირები',
  'article ორგანიზაცია',
  'article პერსონალია',
  'article საკვანძო სიტყვები',
  'article ფოტოები',
  'article მატიანის რუბრიკა'
]



(0..issues.length-1).each do |i|
  puts "working on #{issues[1]}"
  data_merged = []

  # read in the data
  data_issues = CSV.read(issues[i])
  data_articles = CSV.read(articles[i])
  puts("- #{data_issues.length} issues")
  puts("- #{data_articles.length} articles")
  # for each article, find the matching issue comparing year and issue number
  # and then save the two sets of data into data_merged
  data_articles.each_with_index do |data_article, j|
    # first row is header - skip it
    if j > 0
      data_item = nil
      # add issue data
      data_issue = data_issues.select{|data_issue| data_issue[idx_issue_num] == data_article[idx_article_num] && data_issue[idx_issue_year] == data_article[idx_article_year]}.first
      if data_issue
        data_item = data_issue
      else
        data_item = Array.new(issue_col_count)
      end

      # add article data
      data_item += data_article

      # remove the unwanted columns
      idx_cols_to_remove.reverse.each do |idx|
        data_item.delete_at(idx)
      end

      # clean up the text
      (0..data_item.length-1).each do |idx_col|
        if data_item[idx_col] == String
          data_item[idx_col] = data_item[idx_col].chomp.strip
        end
      end

      # create pdf url to forset server
      if !data_item[idx_issue_pdf_name].nil?
        data_item[idx_issue_pdf_name] = pdf_url + data_item[idx_issue_pdf_name]
      end

      # get actual description text
      # - the text could not be isolated during scraping so had to get entire row.
      #   so now need to pull out the description text
      regexp_match = /გვ.[0-9]+\-?[0-9]*\.?\s?\-?\s?(.*)\[MFN/.match(data_item[idx_description])
      data_item[idx_description] = regexp_match.nil? ? nil : regexp_match[1]

      # save the row
      data_merged << data_item
    end
  end


  # write out csv
  CSV.open(merged[i], "wb") do |csv|
    # headers
    csv << csv_headers

    # data
    data_merged.each do |data_item|
      csv << data_item
    end
  end
end




puts "it took #{Time.now - start} seconds"

