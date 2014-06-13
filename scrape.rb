require 'sinatra'
require 'data_mapper'
require 'dm-migrations'

DataMapper.setup(:default, 'sqlite:///Users/josephmin/Developer/HTML/Live-Streaming-Example/tcudata.db')

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
  property :chef_id,        Integer                     # The id of the chef teaching the course
  property :iap_id,         String                      # The IAP ID of the lesson

end

DataMapper.finalize
DataMapper.auto_upgrade!

get '/lessons.json' do
  content_type :json
  lessons = Lesson.all
  lessons.to_json
end

get '/lesson/:id' do
  content_type :json
  temp = Lesson.get(params[:id])
  if (temp.nil?)
    status 404
  else
    temp.to_json
  end
end

