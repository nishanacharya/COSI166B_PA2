# Name: Nishan Acharya
# Email: acharyan@brandeis.edu
# Date: 31st January 2016
# COSI166B
# (PA) Movies-2

class MovieData	

	#constructor 
	def initialize(filename)
		filename = filename + "/u.data"
		@dataSet = load_data(filename)
		@movieRatingHash = createMovieRatingHash()
		@userMovieHash= createUserMovieHash()
	end

	# creates an array dataSet containing array of complete datas	
	def load_data(filename)
		dataSet = Array.new
		file = open(filename, "r")
		file.each_line do |line|
			data = line.split(' ')
			dataSet.push(data) # one data contains user_id, movie_id, rating and timestamp in index 0, 1, 2, 3 respectively
		end
		file.close
		return dataSet
	end

	# Creates a hash of movies tied with all the ratings for that particular movie.
	def createMovieRatingHash()
		movieRatingHash = Hash.new
		@dataSet.each do |data|
			if !movieRatingHash.has_key?(data[1])
				movieRatingHash[data[1]] = Array.new
			end
			movieRatingHash[data[1]].push(data[2])
		end
		return movieRatingHash
	end

	# Popularity is counted as the average rating received by the movie multiplied by the number of ratings it received.
	# Hence, the most popular movie would be the one that would not only receive high rating from users but should have been rated by many
	def popularity(movie_id)
		total = 0.0
		count = 0.0

		ratings = @movieRatingHash[movie_id]
		ratings.each do |star|
			star = star.to_i
			total += star
			count += 1
		end

		average = total / count
		popularity = average * count
	end

	# ties the movie with its popularity rating using the popularity method and then returns the list of most popular movies in descending order
	def popularity_list()
		popularityHash = Hash.new
		@movieRatingHash.each do |movie_id, rating|
			popularityHash[movie_id] = popularity(movie_id)
		end
		popularityHash = Hash[popularityHash.sort_by{|k, v| v}.reverse]
		return popularityHash.keys # returns the list of all movies according to decreasing popularity
	end

	# Creates a hash of users tied with all movies they have rated, which is tied with the rating it received from that user
	def createUserMovieHash()
		userMovieHash = Hash.new
		@dataSet.each do |data|
			if !userMovieHash.has_key?(data[0])
				userMovieHash[data[0]] = Hash.new
			end
			userMovieHash[data[0]][data[1]] = data[2]
		end
		return userMovieHash
	end

	# Similarity between user preference for movies is calculated as the average ratings received by a movie from the two users
	# (movie is common to both users); this average is then summed for all movies that are common to both; this is divided by the number of movies common to both
	# resulting in a similarity rating the same as one used by the users to rate the movies. (for example: if the movie was rated from 1-5, the similarity rating would be from 1-5)
	def similarity(user1, user2)

		count = 0.0
		totalOfAverageRatings = 0.0

		@userMovieHash[user1].each do |movie_id, rating|
			rating = rating.to_i
			if @userMovieHash[user2].has_key?(movie_id)
				count += 1
				totalOfAverageRatings += (rating + @userMovieHash[user2][movie_id].to_i) / 2
			end
		end

		if count == 0.0
			similarity = 0.0
		else
			similarity = totalOfAverageRatings / count 
		end
		return similarity
	end

	# Calculates similarity for all the users who are similar to user1 and returns them in decreasing order (most similar at first)
	def most_similar(user1)
		mostSimilar = Hash.new

		@dataSet.each do |data|
			user2 = data[0]
			if !user1.equal?(user2) 
				mostSimilar[user2] = similarity(user1, user2)
			end
		end

		mostSimilar = Hash[mostSimilar.sort_by{|k, v| v}.reverse]
		return mostSimilar.keys 
	end

	# returns rating given by the user and 0 if no rating was provided
	def rating(user, movie)
		if @userMovieHash[user][movie] == nil 
			return 0
		end
		return @userMovieHash[user][movie] 
	end

	# predicts what rating a user would give to a movie 
	def predict(user, movie)
		total = 0.0
		count = 0.0
		predicter = Hash.new
		@userMovieHash.each do |u, mr|
			if mr.has_key?(movie)
				total += mr[movie].to_f * similarity(user, u)
				count += 1
			end
		end
		return total / (count * 5)	 		
	end

	# returns the list of all the movies watched by the given user
	def movies(user)
		allMovies = Array.new
		@userMovieHash[user].each do |movie_id, rating|
			allMovies.push(movie_id)
		end
		return allMovies
	end

	# returns the list of all the users who watched the given movie
	def viewers(movie)
		allUsers = Array.new
		@userMovieHash.each do |u, mr|
			if mr.has_key?(movie)
				allUsers.push(u)
			end
		end
		return allUsers
	end

	# predicts the rating for the given number of ratings(k) and then creates an object MovieTest with the result
	# MovieTest will include the user_id, movie_id, rating, and the predicted rating
	def run_test(k)
		count = 0
		testObject = MovieTest.new
		@dataSet.each do |data|
			prediction = predict(data[0], data[1])
			testObject.add(data[0], data[1], data[2], prediction)
			count +=1
			if count >= k
				break
			end
		end
		return testObject
	end

	private :createMovieRatingHash, :createUserMovieHash
end

class MovieTest

	# constructor
	def initialize()
		@finalList = Array.new
	end

	# adds the requrired data to the finalList
	def add(user_id, movie_id, rating, prediction)
		data = Array.new([user_id, movie_id, rating, prediction])
		@finalList.push(data)
	end

	# finds the mean error in the prediction rating in comparison to the actual ratings
	def mean()
		error = 0
		@finalList.each do |data|
			error += (data[2].to_f - data[3].to_f).abs
		end
		average = error / @finalList.length
	end

	# returns the standard deviation of the errors 
	def stddev()
		sum = 0
		average = mean()
		@finalList.each do |data|
			error = (data[2].to_f - data[3].to_f).abs
			sum += (error - average)**2
		end
		std = Math.sqrt(sum / (@finalList.length - 1))
	end

	# returns the root mean square error of the prediction
	def rms()
		sumOfDifference = 0
		@finalList.each do |data|
			sumOfDifference += (data[3].to_f - data[2].to_f)**2
		end
		rms = Math.sqrt(sumOfDifference / @finalList.length)
	end

	# returns the list of all the data containg user_id, movie_id, rating, and predicted rating in the form of an array
	def to_a()
		@finalList
	end
end


# Below is the list of test methods for MovieData
z = MovieData.new("ml-100k")
puts "Top 10 popular movie_id are:" 
puts z.popularity_list[0..9]
puts
puts "Top 10 users most similar to user 1 (example) are:" 
puts z.most_similar("1")[0..9]
puts
puts z.rating("196","242")
puts z.predict("166", "346")
puts z.movies("196")
puts z.viewers("242") 

# Below is the list of test methods for MovieTest
t = z.run_test(25)
puts t.mean
puts t.stddev
puts t.rms
puts t.to_a









