# VizHack 2018 WWII Georgian Deaths Scraper
Get a list of all Georgians that died during WWII according to a Russian website https://obd-memorial.ru.

This is the URL to the Georgian deaths.
https://obd-memorial.ru/html/search.htm?d=T~%20%D0%93%D1%80%D1%83%D0%B7%D0%B8%D0%BD%D1%81%D0%BA%D0%B0%D1%8F%20%D0%A1%D0%A1%D0%A0&entity=000000011111110&entities=24,28,27,23,34,22,20,21&ps=100&p=1

I believe this site was built to make scraping as hard as possible so it had to be accomplished in a few different ways.
* Use the web scraper plugin to get all of the record and image ids (see sitemap_get_ids.txt)
* Use ruby and typheous to download the detail pages for each id in the above step
* Use ruby and nokogiri to process the detail pages and create a spreadsheet.

The last two steps could have been combined but due to the number of pages (280,000) I did not know how long it would take to download and process all the files and I was afraied of my internet dying in the middle of the process. So I split them out into two steps so I can make sure all files are downloaded and then I would process them. Because of this the total process was slow.
* get ids - about 4-6 hours to scrape 280,000 records into 60MB of csv data
* download html pages - about 3 hours to download 280,000 files taking up 23GB.
* process html files and save to csv - about 9 hours to generate a 100MB csv file.

# NOTES
* The sitemap for the web scraper plugin is in sitemap_get_ids.txt
* The listings folder has the CSV files that were created for the record IDs. The IDs were downloaded in batches so a script was created to merge the files into a new one. The smaller csv files are zipped together to save space.
* The detail HTML pages are not part of this project - they are 23GB in size. If you run the fast download method it will only take about 3 hours to download them all.
* The final CSV file with all the data is data.csv
