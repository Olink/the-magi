require 'mongo_mapper'
require_relative 'Score'
MongoMapper.setup({'production' => {'uri' => ENV['MONGODB_URI']}}, 'production')

# File.readlines('as_round1_scores.txt').each do |line|
#   line_parsed = line.split ' '
#   score = Score.new({
#     :team_id => line_parsed[0],
#     :r1_score => line_parsed[1],
#     :total_score => line_parsed[1],
#     :division => 'all-service'
#   })
#   if score.save
#     # puts "Stored #{line_parsed[0]} from All Service at #{line_parsed[1]}."
#   else
#     puts "Failed to save #{line_parsed[0]}."
#   end
# end

# File.readlines('open_round1_scores.txt').each do |line|
#   line_parsed = line.split ' '
#   score = Score.new({
#     :team_id => line_parsed[0],
#     :r1_score => line_parsed[1],
#     :total_score => line_parsed[1],
#     :division => 'open'
#   })
#   if score.save
#     # puts "Stored #{line_parsed[0]} from Open at #{line_parsed[1]}."
#   else
#     puts "Failed to save #{line_parsed[0]}."
#   end
# end

File.readlines('open_r12_results.txt').each do |line|
  line_parsed = line.split ' '
  score = Score.where({:team_id => line_parsed[0]}).first
  if score == nil
    score = Score.new({
      :team_id => line_parsed[0],
      :r1_score => 0,
      :r2_score => 0,
      :division => 'open',
      :tier => line_parsed[2]
    })
  else
    score.tier = line_parsed[2]
  end
  if score.save
    # puts "Stored #{line_parsed[0]} from Open at #{line_parsed[1]}."
  else
    puts "Failed to save #{line_parsed[0]}."
  end
end