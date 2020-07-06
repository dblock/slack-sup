class Time
  include DOTIW::Methods

  def ago_in_words(options = {})
    time_ago_in_words(self, options) + ' ago'
  end

  def ago_or_future_in_words(options = {})
    t = Time.current
    if t == self
      'now'
    elsif t > self
      distance_of_time_in_words(self, t, options) + ' ago'
    else
      'in ' + distance_of_time_in_words(t, self, options)
    end
  end
end
