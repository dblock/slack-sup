module TimeAgoInWords
  def ago_or_future_in_words
    t = Time.now
    if t == self
      'now'
    elsif t > self
      secs = t - self
      return 'just now' if secs > -1 && secs < 1

      pair = ago_in_words_pair(secs)
      ary = ago_in_words_singularize(pair)
      ary.empty? ? '' : ary.join(' and ') << ' ago'
    else
      secs = self - t
      return 'about now' if secs > -1 && secs < 1

      pair = ago_in_words_pair(secs)
      ary = ago_in_words_singularize(pair)
      ary.empty? ? '' : 'in ' + ary.join(' and ')
    end
  end
end
