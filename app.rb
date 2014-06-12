require 'sinatra'
require 'rest_client'
require 'sinatra'
require 'json'
enable :sessions

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
  "list of videos for #{session[:userid]} with token #{session[:token]}"
  File.read('videos.html')
end
