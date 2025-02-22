module SlackSup
  module Models
    module Mixins
      module Export
        extend ActiveSupport::Concern

        def export_filename(root, name)
          data_path = File.join(root, name)
          File.join(data_path, "#{name}.zip")
        end

        def export_zip!(root, name, options = {})
          data_path = File.join(root, name)
          data_zip = File.join(data_path, "#{name}.zip")
          export!(data_path, options)
          Zip::File.open(data_zip, create: true) do |zipfile|
            Dir.glob("#{data_path}/**/*").reject { |fn| File.directory?(fn) }.each do |file|
              zipfile.add(file.sub(data_path + '/', ''), file)
            end
          end
          data_zip
        end

        def export!(root, options = {})
          name = options[:name] || self.class.name
          presenter = options[:presenter] || Object.const_get("Api::Presenters::#{self.class.name}Presenter")
          keys = presenter.representable_attrs.keys - ['links']
          data = options[:coll] || Array(self)
          FileUtils.makedirs(root)
          CSV.open(File.join(root, "#{name.downcase}.csv"), 'w', write_headers: true, headers: keys) do |csv|
            data.each do |entry|
              row = presenter.represent(entry).to_hash
              row.merge!(row['_embedded']) if row.key?('_embedded')
              csv << keys.map do |key|
                value = row[key]
                case value
                when Hash
                  value.map do |k, v|
                    "#{k}=#{v}"
                  end.join("\n")
                when Array
                  value.map do |v|
                    v["#{key.singularize}_name"] || v['user_name'] # HACK: assume user id
                  end.join("\n")
                else
                  value
                end
              end
            end
          end
        end
      end
    end
  end
end
