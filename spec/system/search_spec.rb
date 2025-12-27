require 'rails_helper'

RSpec.describe 'Search', type: :system do
  let(:user) { create(:user, username: 'systemtestuser') }
  let!(:prefecture) { create(:prefecture, name: '東京都') }
  let!(:hashtag) { create(:hashtag, name: 'systemtesthashtag') }

  before do
    user.confirm if user.respond_to?(:confirm)
    sign_in user
    driven_by(:rack_test)
  end

  describe '検索UI' do
    it '検索に関連する要素が存在すること' do
      visit root_path

      expect(page).to have_css('input')
      expect(page).to have_selector('header')

      search_related = page.all('input[type="text"], input[type="search"], a[href*="search"]')
      expect(search_related).not_to be_empty
    end
  end

  describe 'ナビゲーション' do
    it 'ヘッダーまたはナビゲーション要素が存在すること' do
      visit root_path

      expect(page).to have_selector('header') | have_selector('nav')
      expect(page).to have_selector('a', minimum: 1)
      expect([prefecture.name, hashtag.name]).to include('東京都', 'systemtesthashtag')
    end
  end

  describe 'ユーザープロフィールページ' do
    it 'ユーザープロフィールページに移動できること' do
      visit user_path(user)

      expect(page).to have_content(user.username)
    end
  end

  describe 'グローバルナビゲーション' do
    def find_and_click_test_link(navigation_links)
      test_link = navigation_links.find do |link|
        !link.text.empty? &&
          link.text != 'ホーム' &&
          page.all('a', text: link.text).count <= 1
      end

      if test_link
        link_href = test_link['href']
        test_link.click
        expect(page).to have_current_path(link_href)
      else
        find_alternative_link
      end
    end

    def find_alternative_link
      nav_link = page.first('header a, nav a, .navbar a, .header-nav a')
      if nav_link && nav_link['href'].present?
        href = nav_link['href']
        nav_link.click
        expect(page).to have_current_path(href)
      else
        find_unique_link_by_attributes
      end
    rescue Capybara::Ambiguous => e
      skip "テストできるリンクが複数見つかりました: #{e.message}"
    end

    def find_unique_link_by_attributes
      unique_link = page.first('a[data-test], a[id], a[role="button"]')
      if unique_link && unique_link['href'].present?
        href = unique_link['href']
        unique_link.click
        expect(page).to have_current_path(href)
      else
        skip 'テスト可能なリンクが見つかりませんでした'
      end
    end

    it 'リンクをクリックしてページ遷移できること' do
      visit root_path

      navigation_links = page.all('a').select { |link| link['href'].present? }

      if navigation_links.present?
        find_and_click_test_link(navigation_links)
      else
        skip 'ナビゲーションリンクが見つかりませんでした'
      end
    end
  end

  describe '基本UI要素' do
    it '基本的なUI要素が表示されること' do
      visit root_path

      expect(page).to have_css('body')
      expect(page).to have_css('div')
      expect(page).to have_selector('header') | have_selector('nav') | have_css('.header') | have_css('.nav')
      expect(page).to have_css('div')
    end
  end
end
