Creates a Semantic Data Collection Changefile for Solve for All based on city data downloaded from geonames.org:
http://download.geonames.org/export/dump/

Running:

  ruby populate <input_dir>

where input_dir contains cities1000.txt, should produce a bzipped Semantic Data Collection Changefile:
cities.json.bz2 in the project directory.

See https://solveforall.com/docs/developer/semantic_data_collection for more info.