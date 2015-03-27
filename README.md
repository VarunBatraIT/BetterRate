## Aim is to add some missing functionality, I wanted for my own project. 
## Fork of RatyRate Stars Rating Gem

[![License](http://img.shields.io/license/MIT.png?color=green)](http://opensource.org/licenses/MIT)


# Setup

Gemfile
```
gem 'betterrate', :github => 'VarunBatraIT/BetterRate'
```

Assuming that you have Movie model and User model

```ruby
  #movie.rb
  betterrate_rateable "Action", "Story" # "Action and Story are two dimensions"
```

```ruby
  #user.rb
  betterrate_rater
```

#Rating Sort considering Overall Avg
```ruby
Movie.betterrate_order() #DESC
Movie.betterrate_order('DESC')
Movie.betterrate_order('ASC')
#Example Output
Movie.betterrate_order('DESC').map(&:id) [4, 1, 5, 6, 7]
Movie.betterrate_order('ASC').map(&:id) [1, 5, 6, 7, 4]
Movie.betterrate_order.map(&:id) [4, 1, 5, 6, 7]
```
#Get  Overall Avg

```
Movie.betterrate_order('DESC').first.rate_overall_average
Movie.betterrate_order('DESC').eager_load(:rate_overall_average)

#Example Output
Movie.betterrate_order('DESC').first.rate_overall_average.avg #4.5
```

#Rate Average with Dimensions


```ruby
Movie.betterrate_order('DESC').eager_load(:rate_average)
Movie.betterrate_order('DESC').first.rate_average
#Example Output
Movie.betterrate_order('DESC').first.rate_average.first.dimension #Action
Movie.betterrate_order('DESC').first.rate_average.first.avg #5.0
```

#Get rater average
```ruby
 Movie.betterrate_order('DESC').first.rater_average
 Movie.betterrate_order('DESC').first.rater_average.first
 ##<AverageCache id: 1, rater_id: 4, rateable_id: 4, rateable_type: "Movie", avg: 4.0, created_at: "2015-03-26 21:15:29", updated_at: "2015-03-26 21:15:29"> 
 s = Movie.betterrate_order('DESC').first.rater_average.map{|ra| ra.rater_id.to_s+' '+ra.avg.to_s}
 ["4 4.0", "5 0.0", "7 5.0"]
```

