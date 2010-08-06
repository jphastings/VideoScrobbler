VideoScrobbler
==============
It keeps track of what videos you're watching!

Why?
----
### It has a good memory
It'll keep track of where you are up to while you're watching a film or episode of TV. This means you can continue playing back where you left off on a different day, computer, continent or even from a different source of video.

### Watch with friends
Make another VideoScrobbler your friend and they'll be able to see what videos you're scrobbling; if you both have the same DVD you can watch it at exactly the same time — even when one of you pauses to pick up the pizza.

How?
----
### The website
This website simply keeps track of what TV, Film and online video you watch. That's it! Simples, eh?

On a side note, this is a proof-of-concept site. I hope I'll be able to make it efficient, secure and pretty but right now I'm pretty sure it's none of those things. If you want to help, it's all written in ruby (with sinatra) and haml, you can see the source code on [github](http://github.com/jphastings/videoScrobbler). Feel free to fork & improve it!

What?!
------
Okay okay, here's a quick [demo video](http://vimeo.com/13946064) showing you how I use my own [demo scrobbler](http://gist.github.com/503240) to keep track of what [I'm watching](/users/jphastings).

### Your computer
Your computer (or any website that supports VideoScrobbling) runs a scrobbler which keeps a beady eye on all the video that you watch, letting this server know what you're watching.

More advanced scrobblers have features like syncing video watching with your friends and telling you where in a series you are.

How can I build a scrobbler?
----------------------------
1. Sign up and [get an api key](/api/account).
2. Take a peek at the [scrobbler layout](/docs/scrobbler_layout.pdf) and the [api docs](/api/docs).
3. Use the [TMDB](http://api.themoviedb.org/2.1) and [TVDB](http://thetvdb.com/wiki/index.php?title=Programmers_API) to get an id for the episode or film. Alternatively for streaming video that *isn't* TV or a film a url will do[^urls].
4. Use the [video.getInfo](/api/docs#video.getInfo) call to get the local id for the video (keep this local id in a cache somewhere).
5. As the user plays the video update [video.scrobble](/api/docs#video.scrobble) with the position, state (playing, paused, stopped, finished) and origin (ie. DVD, tv:uk:bbc1west — these need to be uniform across scrobblers please [look here](/api/docs#origin))
6. Check out my [demo scrobbler](http://gist.github.com/503240) and see if it's helpful!
7. Be awesome.

[^urls]: Please use the canonical form of the url, most video sites have a &lt;meta name="canonical"> tag which is the one you should use, this way there will only ever be one item in our database for each webstream. More info in the [api docs](/api/docs#remote_ids).