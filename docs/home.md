VideoScrobbler
==============
It keeps track of what videos you're watching!

Why?
----
### It has a good memory!
You live in the UK, you go and visit your friend in the US and one afternoon while he's working he tells you to go ahead and watch some of the hilarious TV show [Arrested Development](). You've watched plenty of the show before, but can you remember where you're up to? Ha!

If you VideoScrobble then this site will keep track of where you are in every TV show you're watching, so you can pick up where you left off *no matter how you're watching it*. Caught the first 10 minutes on your [EyeTV]() at home? You can watch the rest from DVD or even YouTube if you can find it.

### It expands your living room!
So you're back in the UK after your trip to see your friend, but the two of you got into watching that show together. VideoScrobbler will tell you what your friends are watching, if you have the same video available you can watch it too - in sync.

How?
----
### The website
This website simply keeps track of what TV, Film and online video you watch. That's it! Simples, eh?

### Your computer
Your computer (or any website that supports VideoScrobbling) runs a scrobbler which keeps a beady eye on all the video that you watch, letting this server know what you're watching.

More advanced scrobblers have features like syncing video watching with your friends and telling you where in a series you are.

No really, I see code, how?
---------------------------
1. Sign up and [get an api key](/api/account).
2. Take a peek at the [api docs](/api/docs).
3. Use the [TMDB](http://api.themoviedb.org/2.1) and [TVDB](http://thetvdb.com/wiki/index.php?title=Programmers_API) to get an id for the episode or film. Alternatively for streaming video that *isn't* TV or a film a url will do[^urls].
4. Use the [video.getInfo](/api/docs#video.getInfo) call to get the local id for the video (keep this local id in a cache somewhere).
5. As the user plays the video update [video.scrobble](/api/docs#video.scrobble) with the position, state (playing, paused, stopped, finished) and origin (ie. DVD, tv:uk:bbc1west — these need to be uniform across scrobblers please [look here](/api/docs#origin))
6. Be awesome.

[^urls]: Please use the canonical form of the url, most video sites have a &lt;meta name="canonical"> tag which is the one you should use, this way there will only ever be one item in our database for each webstream. More info in the [api docs](/api/docs#remote_ids).