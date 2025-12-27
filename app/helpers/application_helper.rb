module ApplicationHelper
  def ranking_badge_class(rank)
    case rank
    when 1
      'bg-yellow-100 text-yellow-800 border-yellow-300'
    when 2
      'bg-gray-100 text-gray-800 border-gray-300'
    when 3
      'bg-orange-100 text-orange-800 border-orange-300'
    else
      'bg-gray-50 text-gray-600 border-gray-200'
    end
  end

  def rank_change_icon(change)
    return content_tag(:span, 'NEW', class: 'text-indigo-600 text-xs font-medium') if change.nil?

    icon_svg = rank_change_svg(change)
    css_class = rank_change_css_class(change)
    display_change = rank_change_display_value(change)

    content_tag(:span, class: "inline-flex items-center #{css_class}") do
      sanitize(icon_svg) + (display_change.nil? ? '' : content_tag(:span, display_change, class: 'ml-1'))
    end
  end

  def remaining_points_class(points)
    if points.zero?
      'text-red-600'
    elsif points <= 2
      'text-yellow-600'
    else
      'text-green-600'
    end
  end

  def default_meta_tags
    {
      site: 'ココじゃ',
      title: 'ココじゃ｜都道府県魅力度ランキングSNS',
      reverse: true,
      charset: 'utf-8',
      description: '「ココじゃ」は、都道府県の魅力を発見・共有できる魅力度ランキングSNSです。あなたの地元や旅先の魅力を投稿して、みんなで盛り上げよう！',
      keywords: 'ココじゃ, 都道府県, 魅力度ランキング, 地域情報, SNS, 観光, 地元',
      canonical: 'https://www.cocoja.jp/',
      separator: '|',
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        type: 'website',
        url: 'https://www.cocoja.jp/',
        image: image_url('cocoja-ogp.png'),
        local: 'ja-JP'
      },
      twitter: {
        card: 'summary_large_image',
        site: '@hyoEngieer01',
        image: image_url('cocoja-ogp.png')
      }
    }
  end

  private

  def svg_path_for_change(change)
    if change.positive?
      'd="M5 10l7-7m0 0l7 7m-7-7v18"'
    elsif change.negative?
      'd="M19 14l-7 7m0 0l-7-7m7 7V3"'
    else
      'd="M5 12h14"'
    end
  end

  def rank_change_svg(change)
    path = svg_path_for_change(change)

    '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">' \
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" ' \
      "#{path}></path>" \
      '</svg>'
  end

  def rank_change_css_class(change)
    if change.positive?
      'text-green-600'
    elsif change.negative?
      'text-red-600'
    else
      'text-gray-500'
    end
  end

  def rank_change_display_value(change)
    return unless change.positive? || change.negative?

    change.abs
  end
end
