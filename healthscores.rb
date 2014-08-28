require 'rubygems'
require 'twilio-ruby'
require 'sinatra'
require 'httparty'
require 'json'
 
get '/healthscores' do
  sender = params[:From]
  body = params[:Body]

  civic_data_url = 'http://www.civicdata.com/api/action/datastore_search_sql'
  resource_id = '6ad5ce43-7c67-425d-8ccc-d18fd95c6d64'
  query = "SELECT * from \"#{resource_id}\" where upper(\"Restaurant Name\") LIKE '#{body.upcase}%'"

  headers = {
        'Content-Type' =>'application/json',
        'Accept' => 'application/json'
      }

  @response_data = HTTParty.get(civic_data_url, :headers => headers, :query => {:sql => query}) #URI::encode(query)
  
  data = @response_data.parsed_response["result"]["records"]
  
  if data.any?
    data.sort! { |id1, id2| id2["Inspection Date"] <=> id1["Inspection Date"] }
    
    latest_inspection = data.first

    inspection_date = Date.parse latest_inspection["Inspection Date"]

    message = "Restaurant Name: #{latest_inspection['Restaurant Name']}\n"
    message += "Address: #{latest_inspection['Address']}"
    message += "Last Inspection Date: #{inspection_date.strftime("%m/%d/%Y")}\n"
    message += "Score: #{latest_inspection['Score']}"
  else
    message = "No restaurant found with the name #{body}"
  end

  #Send the response
  twiml = Twilio::TwiML::Response.new do |r|
    r.Message message
  end
  twiml.text


  

end