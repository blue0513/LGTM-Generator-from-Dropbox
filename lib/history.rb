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

  def should_adopt?(image_name)
    create_history_file_if_needed

    json_data = open(HISTORY_JSON_FILE_PATH) do |io|
      JSON.load(io)
    end

    # NOTE: nil.to_i => 0
    count = json_data[image_name].to_i
    min_count = json_data.sort_by{ |k, v| v.to_i }.first&.last.to_i

    count <= min_count
  end

  def create_history_file_if_needed
    unless File.exist?(HISTORY_JSON_FILE_PATH)
      File.open(HISTORY_JSON_FILE_PATH, 'w') { |f| f.write('{}') }
    end
  end
end
