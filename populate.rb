require 'csv'
require 'json'
require 'fileutils'

class GeonamesCityPopulator

  def initialize(input_dir, output_path)
    @input_dir = input_dir
    @output_path = output_path
  end

  def populate
    @first_document = true

    @num_cities_found = 0

    File.open(@output_path, 'w:UTF-8') do |out|
      out.write <<-eos
{
  "metadata" : {
    "mapping" : {
      "_all" : {
        "enabled" : false
      },
      "properties" : {
        "name" : {
          "type" : "string",
          "index" : "analyzed"
        },
        "asciiName" : {
          "type" : "string",
          "index" : "analyzed"
        },
        "alternateNames" : {
          "type" : "string",
          "index" : "analyzed"
        },
        "location" : {
          "type" : "geo_point"
        },
        "featureClass" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "featureCode" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "countryCode" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "alternateCountryCodes" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "admin1Code" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "admin2Code" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "admin3Code" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "admin4Code" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "population" : {
          "type" : "long"
        },
        "elevationInMeters" : {
          "type" : "float",
          "index" : "no"
        },
        "timezone" : {
          "type" : "string",
          "index" : "not_analyzed"
        }
      }
    }
  },
  "updates" : [
      eos
      
      parse_file(out)

      out.write("\n  ]\n}")
    end

    puts "Found #{@num_cities_found} cities."
  end

  private

  def parse_file(out)
    file_path = File.join(@input_dir, 'cities1000.txt')
    line_number = 1
    bad_lines = 0
    puts "Parsing file '#{file_path}' ..."

    # Parse line by line since there are quoting errors. This is very slow.
    File.open(file_path, 'r').each do |line|
      begin
        CSV.parse(line, col_sep: "\t") do |row|
          output_doc = {
            _id: row[0],
            name: row[1],
            asciiName: row[2],
            alternateNames: (row[3] || '').split(/\s*,\s*/),
            location: {
              lat: row[4].to_f,
              lon: row[5].to_f
            },
            featureClass: row[6],
            featureCode: row[7],
            countryCode: row[8],
            alternateCountryCodes: (row[9] || '').split(/\s*,\s*/),
            admin1Code: row[10],
            admin2Code: row[11],
            admin3Code: row[12],
            admin4Code: row[13],
            population: row[14].to_i,
            elevationInMeters: row[15].to_f,
            timezone: row[16]
          }

          if @first_document
            @first_document = false
          else
            out.write(",\n")
          end

          json_doc = output_doc.to_json
          out.write(json_doc)

          @num_cities_found += 1
        end
      rescue => e
        puts "Bad line #{line_number}: '#{line}'"
        bad_lines += 1
      end
      line_number += 1
    end
    puts "Done parsing file with #{bad_lines} bad lines."
  end
end

input_dir = nil
output_filename = 'cities.json'

ARGV.each do |arg|
  if input_dir
    output_filename = arg
  else
    input_dir = arg
  end    
end

populator = GeonamesCityPopulator.new(input_dir, output_filename)
populator.populate()

system("bzip2 -kf #{output_filename}")