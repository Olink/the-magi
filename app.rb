require 'sinatra'
require 'active_support/core_ext'
require_relative 'Score'
require 'json'
require 'filewatcher'

class Magi < Sinatra::Base
  
  def initialize()
    @shortcut_filename = 'team_shortcuts.json'
    @shortcut_routes = {}
    
    unless File.exist?(shortcut_filename)
      File.open(shortcut_filename, 'w') {|f| f.write('{}') }
    end
  
    FileWatcher.new([@shortcut_filename]).watch do |filename|
      shortcut_file = File.read(@shortcut_filename)
      @shortcut_routes = JSON.parse(shortcut_file)
      puts "Updated " + filename
    end
  end

  get '/rhs/?' do
    redirect to('/teams/07-0152,07-0327,07-1260,07-1262,07-1964,07-0158,07-0639,07-1818')
  end

  get '/lchs/?' do
    redirect to('/teams/07-1889,07-0940,07-0692,07-1887')
  end

  get '/cchs/?' do
    redirect to('/teams/07-1863,07-2427,07-1864,07-1975')
  end
  
  get '/:shortcut/?' do
    if @shortcut_routes.has_key?(params[:shortcut])
      redirect to('/teams/' + @shortcut_routes[params[:shortcut]])
    end

    return erb :error, :locals => {:error => "This team short cut does not exist, have you contacted us?"}
  end
    
  get '/division/:division/?' do
    unless params[:division] == 'all-service' || params[:division] == 'open'
      return erb :error, :locals => {:error => "Invalid division specified. Must either be 'open' or 'all-service'."}
    end

    score_count = Score.where({:division => params[:division]}).count

    scores = Score.where({:division => params[:division]}).sort(:r3_score.desc)

    plat_slots = (score_count * 0.3).round(0)
    last_update = Score.where({:division => params[:division], :tier => 'Platinum', :state => 'CO'}).first.updated_at
    erb :div_platinum, :locals => {:last_update => last_update, :plat_slots => plat_slots, :scores => scores, :teams => score_count, :division => params[:division], :state => params[:state]}
  end

  get '/' do
    redirect to ('/division/open')
  end

  configure do
    MongoMapper.setup({'production' => {'uri' => ENV['MONGODB_URI']}}, 'production')
  end

  get '/team/:teamid/?' do
    scores = Score.where({:team_id => params[:teamid]}).sort(:r3_score.desc)

    if scores.count == 0
      return erb :error, :locals => {:error => "Invalid team ID specified. Team must be a fully qualified ID, e.g. 07-0152."}
    end
    last_update = Score.where({:team_id => params[:teamid]}).first.updated_at
    erb :team, :locals => {:scores => scores, :division => scores.first.division, :state => scores.first.state, :last_update => last_update}
  end

  get '/teams/:teamids/?' do

    unless (params[:teamids].include?(','))
      return erb :error, :locals => {:error => "Invalid team CSV specified. Separate TeamIDs by commas."}
    end

    teams = Array.new
    params[:teamids].split(',').each do |team|
      sc = Score.where({:team_id => team}).sort(:r3_score.desc).first

      unless sc == nil
        teams.push(sc)
      end
    end

    if teams.count == 0
      return erb :error, :locals => {:error => "Invalid team IDs specified. Teams must be fully qualified, e.g. 07-0152,06-0238, etc."}
    end

    last_update = teams[0].updated_at
    erb :teams, :locals => {:teams => teams, :last_update => last_update}
  end

  get '/:state/:division/?' do
    score_count = Score.where({:division => params[:division], :state => params[:state]}).count

    if score_count == 0
      return erb :error, :locals => {:error => 'Invalid state / division combo specified. No data found.'}
    end

    teams = Score.where({:division => params[:division], :state => params[:state]}).sort(:r3_score.desc)

    erb :teams, :locals => {:teams => teams}
  end
end