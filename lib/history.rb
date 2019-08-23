require 'json'

module History
  module_function

  HISTORY_JSON_FILE_PATH = 'history.json'.freeze

  def write_history(image_name)
    create_history_file_if_needed

    json_data = open(HISTORY_JSON_FILE_PATH) do |io|
      JSON.load(io)
    end

    # counter increment
    json_data[image_name] = (json_data[image_name] || 0) + 1

    open(HISTORY_JSON_FILE_PATH, 'w') do |io|
      JSON.dump(json_data, io)
    end
  end

  def should_adopt?(image_name, dropbox_files)
    create_history_file_if_needed

    counts_by_filename = open(HISTORY_JSON_FILE_PATH) do |io|
      JSON.load(io)
    end

    count = counts_by_filename[image_name] || 0
    min_count = calculate_min_count(counts_by_filename, dropbox_files)

    count <= min_count
  end

  def calculate_min_count(counts_by_filename, dropbox_files)
    filenames = counts_by_filename.keys

    if (dropbox_files - filenames).size > 0
      # There are files not in the history
      0
    else
      counts_by_filename.
        select { |k,v| dropbox_files.include?(k) }.
        values.min
    end
  end

  def create_history_file_if_needed
    unless File.exist?(HISTORY_JSON_FILE_PATH)
      File.open(HISTORY_JSON_FILE_PATH, 'w') { |f| f.write('{}') }
    end
  end
end
