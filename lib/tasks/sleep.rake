namespace :sleep do
  desc "既存ページの睡眠レコードの end_time を日付順に再連結する"
  task reconcile: :environment do
    count = 0
    Page.order(:date).each do |page|
      page.reconcile_sleep_boundaries!
      count += 1
    end
    puts "#{count}ページを処理しました"
  end
end
