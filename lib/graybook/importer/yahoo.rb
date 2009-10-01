require 'graybook/importer/page_scraper'
require 'fastercsv'

##
# contacts importer for Yahoo!

class Graybook::Importer::Yahoo < Graybook::Importer::PageScraper

  ##
  # Matches this importer to an user's name/address

  def =~(options = {})
    options && options[:username] =~ /@yahoo.co(m|\.uk)$/i ? true : false
  end

  ##
  # login for Yahoo!

  def login
    page = agent.get('https://login.yahoo.com/config/login_verify2?')
    form = page.forms.first
    form.login = options[:username].split("@").first
    form.passwd = options[:password]
    page = agent.submit(form, form.buttons.first)

    if page.body =~ /Invalid ID or password./ || page.body =~ /This ID is not yet taken./
      return Graybook::Problem.new("Username and password were not accepted. Please check them and try again.")
    end

    true
  end

  ##
  # prepare the importer

  def prepare
    login
  end

  ##
  # scrape yahoo contacts

  def scrape_contacts
    page = agent.get("http://address.yahoo.com/?1=&VPC=import_export")
    if page.body =~ /To access Yahoo! Address Book\.\.\..*Sign in./m
      return Graybook::Problem.new("Username and password were not accepted. Please check them and try again.")
    end
    form = page.forms.last
    csv = agent.submit(form, form.buttons[2]) # third button is Yahoo-format CSV

    contact_rows = FasterCSV.parse(csv.body)
    labels = contact_rows.shift # TODO: Actually use the labels to find the indexes of the data we want
    contact_rows.collect do |row|
      next if !row[7].empty? && options[:username] =~ /^#{Regexp.escape(row[7])}/ # Don't collect self
      {
        :name  => "#{row[0]} #{row[2]}".to_s,
        :email => (row[4] || "#{row[7]}@yahoo.com") # email is a field in the data, but will be blank for Yahoo users so we create their email address
      }
    end
  end

  Graybook.register(:yahoo, self)
end