# Stolen from here: https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#Ruby
def calculate_levenhstein(word_a, word_b)
  matrix = [(0..word_a.length).to_a]
   (1..word_b.length).each do |j|
     matrix << [j] + [0] * (word_a.length)
   end

   (1..word_b.length).each do |i|
     (1..word_a.length).each do |j|
       if word_a[j-1] == word_b[i-1]
         matrix[i][j] = matrix[i-1][j-1]
       else
         matrix[i][j] = [
           matrix[i-1][j],
           matrix[i][j-1],
           matrix[i-1][j-1],
         ].min + 1
       end
     end
   end
   return matrix.last.last
end


require 'net/http'
require 'json'

def http_get(uri_str, limit = 10)
	raise ArgumentError, 'too many HTTP redirects' if limit == 0

	uri = URI(uri_str)
	Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
		request = Net::HTTP::Get.new uri
		response = http.request request # Net::HTTPResponse object

		case response
			when Net::HTTPSuccess then
				return JSON.parse(response.body)

			when Net::HTTPRedirection then
				location = response['location']
				puts "redirected to #{location}"
				puts "limit: #{limit}"
				fetch(location, limit - 1)

			else
				#puts "Fetch failed"
				return  JSON.parse("{}")
		end
	end
end

GOOGLE_API_KEY = 'Get your own api key at https://console.developers.google.com'
def query_google(english_word, target_language)
  url = "https://www.googleapis.com/language/translate/v2?q=#{english_word}&target=#{target_language}&format=text&source=en&key=#{GOOGLE_API_KEY}"
  resp = http_get(url)['data']['translations'][0]['translatedText']
  return resp
end

def load_wordlist()
  ret = []
  File.open("./nouns.txt", "r") do |f|
    f.each_line do |line|
      ret << line.gsub(/(\r|\n|\t| )*/, '').downcase # GO AWAY WHITESPACE!
    end
  end
  return ret
end

def append_to_file(filename, output)
  File.open(filename, "a") do |f| #Remember to manually delete the file between runs or you'll end up with dupes :)
    f.write output
  end
end

words = load_wordlist()
words.each_with_index do |word, index|
  translation = query_google(word, 'da').downcase
  levenshtein_distance = calculate_levenhstein(word, translation)
  append_to_file("./distances.csv", "#{word},#{translation},#{levenshtein_distance}\n")
  puts "(#{index+1}/#{words.length}) #{word} -> #{translation} -> #{levenshtein_distance}"
end
