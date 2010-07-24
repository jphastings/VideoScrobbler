VideoScrobbler API
==================

Basic plan: copy the [last.fm API](http://www.last.fm/api/intro). The service will only record and return the videos played, rather than providing a forum for discussion like last.fm does.

This service won't hold information about the films/tv/videos, instead it'll just hold themoviedb.org or thetvdb.com reference ids.

To avoid last.fm's problem with double entries and tag matching and so on, I'll only accept ids from themoviedb.org and thetvdb.org as indices.

Errors
------
The last.fm error codes are used, some are irrelevant so relevant ones are repeated here. Suitable HTTP status codes will also be sent. (TODO: add these to the following list)

- 8: **Operation Failed** - Server Error. Please try again later.
- 2: **Invalid service** -This service does not exist
- 3: **Invalid Method** - No method with that name in this package
- 4: **Authentication Failed** - You do not have permissions to access the service
- 5: **Invalid format** - This service doesn't exist in that format
- 6: **Invalid parameters** - Your request is missing a required parameter or a parameter is invalid
- 7: **Invalid resource specified** (or that local id doesn't exist in the database)
- 9: **Invalid session key** - Please re-authenticate
- 10: **Invalid API key** - You must be granted a valid key by last.fm
- 11: **Service Offline** - This service is temporarily offline. Try again later.
- 13: **Invalid method signature supplied**
- 26: **Suspended API key** - Access for your account has been suspended, please contact Last.fm

Request ids
-----------
When sending requests relating to video objects you may reference by local id or by a specific service with a prefix like this:

	id: 123456
	id: tvdb:2345
	id: tmdb:3456

### Video
#### video.getInfo
##### Request
	id: <the request id>
	user: (optional) <user id> the user the extended info should be about

Requesting information by an id which doesn't exist will result in an error 7. Requesting information on a user that doesn't exist will get the result as if no user had been specified.

In this method alone you can also use urls as request ids:

	id: http://vimeo.com/12850662

Please only use this for streams which aren't covered under 'films' (via TMDB) or 'tv' (via TVDB).

Also, please do your best to trim the cruft from the URL — unnecessary get/hash parameters etc — eg. youtube links should be: http://www.youtube.com/watch?v=Kx-78v6WLN8 — good HTML usually has a 'canonical' meta tag, which should be the definitive url to use.

Please use the local id as soon as you know it, as there is obviously overhead in checking for HTTP redirects and grabbing metadata where available.

Finally, if in doubt, try and hunt down a permalink on the page currently being viewed. You should use this method to generate a local id for streams for use in other method calls, please try and keep a cache of them on the scrobbler end!

##### Response
	id: <local id>
	type: <type of video>
	plays: <number of plays>
	active: <number of users currently watching this video>
	popularity: <a float between 0 and 1 representing this video's popularity>
	
For films:
	type: film
	name: <name of film>
	tmdbid: <themoviedb id>
	
For TV:
	type: tv
	name: <name of episode>
	showname: <name of show>
	series: <series number>
	episode: <episode number>
	tvdbid: <thetvdb id>
	
For URLs:
	type: url
	name: <the name as best scraped from the url>
	url: <the url>
	
If user is specified AND the data is available to you
	user: <the user this extended info is about, if requested>
	loved: true|false
	state: playing|stopped
	position: <the position in seconds the server last scrobbled you at>

#### video.love
Mark (or unmark) a track as loved.
##### Request
	id: <request id>
	love: true|false
##### Response
	id: local id
	love: the stored loved value

### Scrobble
#### scrobble.position
Requires user to be logged in.

Informs the server that the user is at a given position through the video.

Scrobblers can send a scrobble.position request at suitable points to provide a playhead bookmarking syncing service across computers. Paused videos will appear on lists of what's currently being watched, stopped ones won't.

Unless you need the information scrobblers should send a HEAD request for this, to save resources with the response. The request is streamlined for low bandwidth use — giggidy.

##### Request
	i: <local id>
	p: <position in seconds - can be a float if you want, but don't be silly>
	s: p|r|s <that is; playing|resting|stopped>
	o: (optional) <source reference>

I'll need to put some more thought into this, but if you're scrobbling live TV then you'd put 'tv:uk:BBC1West' or 'tv:us:SyFy' other sources might be 'dvd', 'itunes' or any other terse descriptor. Any string is acceptable. The aim of this is so that friends can coordinate watching the same videos at roughly the same time.

If in doubt, leave origin empty (certainly for URL videos).

##### Response
	id: local id
	position: the stored position in seconds
	state: playing|resting|stopped
	origin: 

### User
#### user.getInfo
The information in the response will be modified by privacy settings (ie. currently watching )
##### Request
	user: <user id>
##### Response
	user: <username>
	since: <signed up on — unixtimestamp format>
	watching: <comma separated local ids of current playing or paused tracks>

#### user.getLovedVideos
Lists all the loved videos by this person, optionally you can specify a specific type. As usual, what is visible is modified by privacy settings.
##### Request
	user: <user id>
	type: (option) tv|film|url
##### Response
	user: <user id>
	type: all|tv|film|url
	videos: (array of)
		<identical elements as the video.getInfo response>

#### user.getRecentVideos
Lists the last n videos watched by this person, optionally you can specify a specific type. As usual, what is visible is modified by privacy settings.

Limits as to the value of n should probably be imposed.
##### Request
	user: <user id>
	type: (option) tv|film|url
	n: <number of items desired>
##### Response
	user: <user id>
	type: all|tv|film|url
	videos: (array of)
		finshedat: <unixtimestamp>
		<identical elements as the video.getInfo response>

