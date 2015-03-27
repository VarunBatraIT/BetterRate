#BetterRate RoR wrapper of Raty plugin

Fork of [RatyRate](https://github.com/wazery/ratyrate) Stars Rating Gem

Wanted much more funcionality, didn't want to hack around so created my own. 

[![License](http://img.shields.io/license/MIT.png?color=green)](http://opensource.org/licenses/MIT)


# Setup

Gemfile
```
gem 'betterrate', :github => 'VarunBatraIT/BetterRate'
```

Terminal
```
rails g betterrate user
rake db:migrate
```

Include js files
```
//= require jquery.raty
//= require betterrate
```

Assuming that you have Movie model and User model

```ruby
  #movie.rb
  betterrate_rateable "Action", "Story" # "Action and Story are two dimensions"
```
Note that dimensions can't have spaces since it creates functions dynamically, due to sorting, I won't be handle it everywhere. Please make sure you do your homework.

```ruby
  #user.rb
  betterrate_rater
```


#View
```
Movie  : <%= rating_for @movie, "Action" %>
Story : <%= rating_for @movie, "Story" %>
```

#Other Helpers

Shows overall rater avg
```
<%= imdb_style_rating_for(@movie, user)  %>
Shows stars of rater per dimensions
<%= rating_for_user @movie, current_user, "Story" %>
<%= rating_for_user @movie, current_user, "Story", {:disable_after_rate => true} %>
View Only User rating, user can't edit it
<%= rating_for_user(@movie, current_user, "Story" , {:disable_after_rate => true, :readonly => true} %>
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

