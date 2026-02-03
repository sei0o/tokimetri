namespace :data do
  desc "Migrate analyzed_content from CSV to JSON format"
  task migrate_csv_to_json: :environment do
    require "csv"

    pages_with_csv = Page.where.not(analyzed_content: nil).where.not(analyzed_content: "")

    puts "Found #{pages_with_csv.count} pages with analyzed_content"

    migrated_count = 0
    skipped_count = 0
    error_count = 0

    pages_with_csv.each do |page|
      begin
        # Check if it's already JSON
        if page.analyzed_content.strip.start_with?("{")
          puts "Page #{page.id} (#{page.date}) - Already JSON, skipping"
          skipped_count += 1
          next
        end

        # Parse CSV
        csv_data = CSV.parse(page.analyzed_content, headers: true)

        # Convert to JSON format
        records = []
        csv_data.each do |row|
          records << {
            start: row["start"] == "_" ? nil : row["start"],
            end: row["end"] == "_" ? nil : row["end"],
            what: row["what"] == "_" ? nil : row["what"],
            category: row["category"] == "_" ? nil : row["category"]
          }
        end

        json_data = { records: records }

        # Update the page
        page.update_column(:analyzed_content, json_data.to_json)

        puts "Page #{page.id} (#{page.date}) - Migrated #{records.size} records"
        migrated_count += 1

      rescue => e
        puts "Page #{page.id} (#{page.date}) - ERROR: #{e.message}"
        error_count += 1
      end
    end

    puts "\nMigration complete!"
    puts "Migrated: #{migrated_count}"
    puts "Skipped (already JSON): #{skipped_count}"
    puts "Errors: #{error_count}"
  end
end
