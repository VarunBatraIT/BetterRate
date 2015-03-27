require 'active_support/concern'
module Betterrate
  extend ActiveSupport::Concern

  def rate(stars, user, dimension=nil, dirichlet_method=false)
    dimension = nil if dimension.blank?

    if can_rate? user, dimension
      rates(dimension).create! do |r|
        r.stars = stars
        r.rater = user
      end
      if dirichlet_method
        update_rate_average_dirichlet(stars, dimension)
      else
        update_rate_average(stars, dimension)
      end
    else
      update_current_rate(stars, user, dimension)
    end
  end

  def update_rate_average_dirichlet(stars, dimension=nil)
    ## assumes 5 possible vote categories
    dp = {1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 1}
    stars_group = Hash[rates(dimension).group(:stars).count.map { |k, v| [k.to_i, v] }]
    posterior = dp.merge(stars_group) { |key, a, b| a + b }
    sum = posterior.map { |i, v| v }.inject { |a, b| a + b }
    davg = posterior.map { |i, v| i * v }.inject { |a, b| a + b }.to_f / sum

    if average(dimension).nil?
      send("create_#{average_assoc_name(dimension)}!", {avg: davg, qty: 1, dimension: dimension})
    else
      a = average(dimension)
      a.qty = rates(dimension).count
      a.avg = davg
      a.save!(validate: false)
    end
  end

  def update_rate_average(stars, dimension=nil)
    if average(dimension).nil?
      send("create_#{average_assoc_name(dimension)}!", {avg: stars, qty: 1, dimension: dimension})
    else
      a = average(dimension)
      a.qty = rates(dimension).count
      a.avg = rates(dimension).average(:stars)
      a.save!(validate: false)
    end
  end

  def update_current_rate(stars, user, dimension)
    current_rate = rates(dimension).where(rater_id: user.id).take
    current_rate.stars = stars
    current_rate.save!(validate: false)
    update_overall_avg(user)
    if rates(dimension).count > 1
      update_rate_average(stars, dimension)
    else # Set the avarage to the exact number of stars
      a = average(dimension)
      a.avg = stars
      a.save!(validate: false)
    end
  end

  def update_overall_avg(user = nil)
    unique_dimensions = self.dimensions.count
    if user.nil?
      total_rates = Rate.where(rateable: self).sum('stars')
      unique_rates = Rate.distinct.where(rateable: self).count('rater_id')
      avg = total_rates.to_f/(unique_dimensions*unique_rates).round(1)
      avg = avg.round(1)
      oa = OverallAverage.where(rateable: self).first || OverallAverage.new
      oa.rateable = self
      oa.avg=avg
      oa.save
    else
      total_rates = Rate.where(rateable: self).where(rater_id: user.id).sum('stars')
      avg = total_rates.to_f/(unique_dimensions).round(1)
      avg = avg.round(1)
      ac = AverageCache.where(rateable: self).where(rater_id: user.id).first || AverageCache.new
      ac.rater_id =user.id
      ac.rateable = self
      ac.avg = avg
      ac.save
      update_overall_avg #update new rating
    end
    avg
  end

  def overall_avg(user = nil)
    if user.nil?
      return calculate_overall_average
    end
    avg = AverageCache.where(rateable: self).where(rater_id: user.id).pluck('avg').first
    if avg.nil?
      avg = update_overall_avg(user)
    end
    avg
  end

  # calculate the movie overall average rating for all users
  def calculate_overall_average
    avg = OverallAverage.where(rateable: self).pluck('avg').first
    if avg.nil?
      avg = update_overall_avg
    end
    avg
  end

  def average(dimension=nil)
    send(average_assoc_name(dimension))
  end

  def average_assoc_name(dimension = nil)
    dimension ? "#{dimension}_average" : 'rate_average_without_dimension'
  end

  def can_rate?(user, dimension=nil)
    rates(dimension).where(rater_id: user.id).size.zero?
  end

  def rates(dimension=nil)
    dimension ? self.send("#{dimension}_rates") : rates_without_dimension
  end

  def raters(dimension=nil)
    dimension ? self.send("#{dimension}_raters") : raters_without_dimension
  end

  module ClassMethods

    def betterrate_rater
      has_many :ratings_given, :class_name => "Rate", :foreign_key => :rater_id
    end

    def betterrate_rateable(*dimensions)
      define_method(:dimensions) do
        dimensions
      end
      self.define_singleton_method(:dimensions) do
        dimensions
      end
      #helps ordering
      scope :betterrate_order, ->(order_by = 'DESC') { joins(' Left Join '+OverallAverage.table_name+' as oa ON oa.rateable_id  = '+eval(self.name).table_name+'.id AND oa.rateable_type = "'+self.name+'"').order('oa.avg ' + (order_by.downcase == "asc" ? "ASC" : "DESC")) }

      has_many :rates_without_dimension, -> { where dimension: nil }, :as => :rateable, :class_name => "Rate", :dependent => :destroy
      has_many :raters_without_dimension, :through => :rates_without_dimension, :source => :rater

      has_one :rate_average_without_dimension, -> { where dimension: nil }, :as => :cacheable,
              :class_name => "RatingCache", :dependent => :destroy

      has_many :rate_average, -> { where.not dimension: nil }, :as => :cacheable,
               :class_name => "RatingCache", :dependent => :destroy

      has_one :rate_overall_average, :as => :rateable,
              :class_name => "OverallAverage", :dependent => :destroy

      has_many :rater_average, :as => :rateable,
               :class_name => "AverageCache", :dependent => :destroy

      dimensions.each do |dimension|
        has_many "#{dimension}_rates".to_sym, -> { where dimension: dimension.to_s },
                 :dependent => :destroy,
                 :class_name => "Rate",
                 :as => :rateable

        has_many "#{dimension}_raters".to_sym, :through => :"#{dimension}_rates", :source => :rater

        has_one "#{dimension}_average".to_sym, -> { where dimension: dimension.to_s },
                :as => :cacheable, :class_name => "RatingCache",
                :dependent => :destroy
      end
    end
  end

end

class ActiveRecord::Base
  include Betterrate
end
