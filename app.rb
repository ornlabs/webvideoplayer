require 'sinatra'
require 'rest_client'
require 'sinatra'
require 'json'
enable :sessions
set :static, true
get '/' do
  File.read('postUserNameAndPassword.html')
end

post '/session' do
  "The username is #{params['userid']} and the password is #{params['password']}"
 x = RestClient.post "https://account.topchefuniversityapp.com/api/v3/tcu/session", :userid =>" #{params['userid']}",:password => "#{params['password']}"
  parsed = JSON.parse(x)
  session[:userid] = params['userid']
  session[:token] = parsed["token"]
  redirect to('/videos')
end

get '/videos' do
 session[:userid]
 session[:token] 
 File.read('videos.html.erb')
end

#get'/HLSprovider-0.7.1/test/osmf/lib/swfobject.js' do
#  File.read("HLSprovider-0.7.1/test/osmf/lib/swfobject.js")
#end
#get '/HLSprovider-0.7.1/test/osmf/lib/ParsedQueryString.js' do
#  File.read('HLSprovider-0.7.1/test/osmf/lib/ParsedQueryString.js') 
#end
get '/lessons.json' do
  File.read('lessons.json')
end
