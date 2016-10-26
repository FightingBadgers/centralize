This script takes a center point by geocoding a city name, landing you in the center of that city.
Then it starts drawing points downwards on the latitude line, reverse geocoding each point to see if we are still in the city.
Once we are no longer in the city, we have found the edge of the city, and now have a radius for the entire city.
We devide that radius by the center_slice to find out what the radius for just the city center is.
We then use the Google Location services to find the entities we are looking for.
