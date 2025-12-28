module PostsHelper
  def format_content_with_hashtags(content)
    return '' if content.blank?

    pattern = /[#＃]([^\s#＃]+)/

    formatted_content = content.gsub(pattern) do |tag|
      tag_name = ::Regexp.last_match(1)
      link_to tag, "/posts/hashtag/#{tag_name}", class: 'text-blue-600 hover:underline'
    end

    formatted_content = formatted_content.gsub(/\r\n|\r|\n/, '<br>')

    sanitize(formatted_content, tags: %w[a br], attributes: %w[href class])
  end

  def extract_hashtags(content)
    return [] if content.blank?

    content.scan(/[#＃]([^\s#＃]+)/).flatten.map(&:downcase).uniq
  end

  def format_content_without_links(content)
    return '' if content.blank?

    pattern = /[#＃]([^\s#＃]+)/

    content_with_tags = content.gsub(pattern) do |tag|
      content_tag(:span, tag, class: 'text-blue-600')
    end

    content_with_tags = content_with_tags.gsub(/\r\n|\r|\n/, '<br>')

    sanitize(content_with_tags, tags: %w[span br], attributes: ['class'])
  end
end
