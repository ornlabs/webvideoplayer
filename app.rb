require 'sinatra'
require 'rest_client'
require 'erb'
require 'sinatra'
require 'json'
require 'sinatra'
require 'data_mapper'
require 'dm-migrations'
enable :sessions
set :static, true


DataMapper.setup(:default, 'sqlite:///Users/josephmin/Developer/HTML/webvideoplayer/tcudata.db')
#DataMapper.setup(:default, 'sqlite:///Users/tomreinhart/Desktop/tcudata.db')

class Lesson
  include DataMapper::Resource
  property :id,             Serial                      # An auto-increment integer key
  property :title,          String                      # A varchar type string, for short strings
  property :description,    String, :length => 1024     # The description of the cake
  property :video_length,   Integer                     # The length of the video, in seconds
  property :videoname,      String                      # The file name for the video, formatted v###
  property :techniques,     String                      # An array of the cooking techniques used
  property :difficulty,     String                      # An adjectival description of the difficulty level
  property :lesson_length,  String                      # Unknown use. <===============================================
  property :notes,          String                      # Notes
  property :favorite,       Integer                     # 0 if not favorited
  property :mastered,       Integer                     # 0 if not mastered
  property :course_id,      Integer                     # The id of the course
  property :chef_id,        Integer                     # The id of the chef teaching the lesson
  property :iap_id,         String                      # The IAP ID of the lesson
end

class Course
  include DataMapper::Resource
  property :id,             Serial                      # An auto-increment integer key
  property :title,          String                      # A varchar type string, for short strings
  property :description,    String, :length => 1024     # The description of the course  
  property :iap_id,         String                      # The IAP ID of the course

  has n, :lessons
end

class Chef
  include DataMapper::Resource
  property :id,              Serial
  property :biotext,         String, :length => 1024
  property :firstname,       String
  property :lastname,        String
  property :shortname,       String
  property :season_number,   Integer
  property :teaches,         String
  property :videoname,       String
  property :order_idx,       Integer
end
DataMapper.finalize
DataMapper.auto_upgrade!



get '/' do
  File.read('postUserNameAndPassword.html')
end

get '/lessons' do
  content_type :json
  lessons = Lesson.all
  lessons.to_json
end

get '/course/:courseID' do
  erb :courseInfo, :locals => {:courseID => params['courseID']}
end

get '/courses/:courseID' do
  content_type :json
  lessons = Lesson.all(:course_id => params[:courseID])
  lessons.to_json
end

get '/chefs' do
   content_type :json
   chefs = Chef.all
   chefs.to_json
end

get '/lessons/:id' do
  content_type :json
  temp = Lesson.get(params[:id])
  if (temp.nil?)
    status 404
  else
    temp.to_json
  end
end

get '/courses' do
  content_type :json
  courses = Course.all
  courses.to_json
end

get '/course_list' do
  File.read('courses.html')
end

post '/session' do
  "The username is #{params['userid']} and the password is #{params['password']}"
  x = RestClient.post "https://account.topchefuniversityapp.com/api/v3/tcu/session", :userid =>" #{params['userid']}",:password => "#{params['password']}"
  parsed = JSON.parse(x)
  session[:userid] = params['userid']
  session[:token] = parsed["token"]
  redirect to('/videos')
end

get '/videos/:videoID' do
  content_type :json
  lesson = Lesson.all(:id => params['videoID'])
  lesson.to_json
end

get '/video/:videoID' do
  session[:userid]
  session[:token] 
  erb :videos, :locals => {:videoID => params[:videoID]}
end

get '/main' do 
  session[:userid]
  session[:token]
  File.read('mainMenu.html')
end


