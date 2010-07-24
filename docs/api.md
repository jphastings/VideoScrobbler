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
- 7: **Invalid resource specified**
- 9: **Invalid session key** - Please re-authenticate
- 10: **Invalid API key** - You must be granted a valid key by last.fm
- 11: **Service Offline** - This service is temporarily offline. Try again later.
- 13: **Invalid method signature supplied**
- 26: **Suspended API key** - Access for your account has been suspended, please contact Last.fm

## Remote ids ## {#remote_ids}

When sending requests relating to [video.getInfo](#video.getInfo) you may reference by local id or by a specific service with a prefix like this:

	id: 123456
	id: tvdb:2345
	id: tmdb:3456
	id: http://vimeo.com/12850662
	
Please only use the URL version for streams which aren't covered under 'films' (via TMDB) or 'tv' (via TVDB). ie. Online episode of South Park from the Comedy Central website should be scrobbled under their TVDB id.

Also, please do your best to trim the cruft from the URL — unnecessary get/hash parameters etc — eg. youtube links should be: [http://www.youtube.com/watch?v=Kx-78v6WLN8](http://www.youtube.com/watch?v=Kx-78v6WLN8) — good HTML usually has a 'canonical' meta tag, which should be the definitive url to use.

Finally, if in doubt, try and hunt down a permalink on the page currently being viewed. You should use this method to generate a local id for streams for use in other method calls, please try and keep a cache of them on the scrobbler end!
	
## Making calls to the API

All calls to this service (which can be found at /api/1.0/) should have the following parameters at least:
	
	api_key: [Your developer api key (go to /api/account)]
	api_sig: [a signautre of your parameters, see below]
	method: [method name]

After having called auth.getSession all following calls should contain:

	sk: [your session key]
	
This session key is what gives you the rights to the service, you will need to send the user to the user-authentication website (auth.allow) to allow access to private data from their perspective for your application.

## Origins ## {#origins}

Setting the origin of the video you're watching is a useful way to let friends know how to access the video you're watching.

If you're scrobbling live TV then you'd put 'tv:uk:BBC1West' or 'tv:us:SyFy' other sources might be 'dvd', 'file:720p' or any other terse descriptor. Any string is acceptable.

If a video is continued using a different origin then a **new** video entry is created, so that the statistics of what sources are being used stays intact.


### Authentication
#### auth.getToken #### {#auth.getToken}

If you wish to authenticate as a specific user, then you need to point the user to /api/auth with your `api_key` and `token` as parameters, once the user has logged in and accepted that your application will have access to their data then your token will provide you with a session key with additional privileges (via auth.getSession).

##### Request


No additional parameters required 
##### Response

	token: [token]

#### auth.getSession #### {#auth.getSession}

All methods other than this one must have an `sk` parameter, you can get an anonymous one with this method, or one attached to a user.

These session keys do not have an expiry date, so once a session key has been generated please use that one permanently, unless you need to authenticate as a different user.

##### Request

	token: [the token you are authenticating with]

##### Response

	user: [user id]
	sk: [a session key for future requests]

### Video
#### video.getInfo #### {#video.getInfo}
##### Request

	id: [the request id]
	username: (optional) [user id] the user the extended info should be about

Requesting information by an id which doesn't exist will result in an error 7. Requesting information on a user that doesn't exist will get the result as if no user had been specified.

##### Response

	id: [local id]
	type: film|tv|url
	remote_id: [the tvdb id, tmdb id or url]
	plays: [number of plays]
	active: [number of users currently watching this video]
	popularity: [a float between 0 and 1 representing this video's popularity]
	
If user is specified AND the data is available to you:

	user:
		username: [the user this extended info is about, if requested]
		loved: true|false
		state: playing|stopped
		position: [the position in seconds the server last scrobbled you at]
		plays: [number of times played]

#### video.love #### {#video.love}

Mark (or unmark) a track as loved.

##### Request

	id: [local id]
	love: true|false
	
##### Response

	id: [local id]
	love: [the stored loved value]

#### video.scrobble #### {#video.scrobble}

Requires user to be logged in.

Informs the server that the user is at a given position through the video. It is good practice to send a scrobble immediately the user starts playing a video with `position = 0`.

Scrobblers can send a scrobble.position request at suitable points to provide a playhead bookmarking syncing service across computers. Paused videos will appear on lists of what's currently being watched, stopped ones won't.

Unless you need the information scrobblers should send a HEAD request for this.

##### Request

	id: [local id]
	position: [position in seconds - can be a float if you want, but don't be silly]
	state: playing|paused|stopped|finished
	origin: (optional) [source reference]

If in doubt, leave origin empty (certainly for URL videos).

##### Response

	id: [local id]
	position: [the stored position in seconds]
	state: playing|resting|stopped|finished
	origin: [the given source reference]
	continued: true|false (if this is the first scrobble ever/since this video was finished this will be false)

### User
#### user.getInfo #### {#user.getInfo}

The information in the response will be modified by privacy settings (ie. currently watching )

##### Request

	username: [username]
	
##### Response

	username: [username]
	since: [signed up on — unixtimestamp format]
	
For friends/yourself only:

	watching: [comma separated local ids of current playing or paused tracks]

#### user.getLovedVideos #### {#user.getLovedVideos}

Lists all the loved videos by this person, optionally you can specify a specific type. As usual, what is visible is modified by privacy settings.

##### Request

	user: [user id]
	type: (option) tv|film|url
	
##### Response

	user: [user id]
	type: all|tv|film|url
	videos: (array of)
		[identical elements to the video.getInfo response]

#### user.getRecentVideos #### {#user.getRecentVideos}

Lists the last n videos watched by this person, optionally you can specify a specific type. As usual, what is visible is modified by privacy settings.

Limits as to the value of n should probably be imposed.

##### Request

	user: [user id]
	type: (option) tv|film|url
	n: [number of items desired]
	
##### Response

	user: [user id]
	type: all|tv|film|url
	videos: (array of)
		finshed: [unixtimestamp]
		[identical elements as the video.getInfo response]

#### user.getFriends #### {#user.getFriends}

Limited to 100 on a page.

##### Request

	username: (optional) [username] (default = logged in user)
	
##### Response

	user: [user id]
	page: [page number]
	count: [number of friends]
	friends: (array of)
		[identical elements to user.getInfo]