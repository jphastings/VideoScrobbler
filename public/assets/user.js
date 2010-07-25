$(document).ready(function() {
	$("time.timeago").timeago();
	
	$("li.video.unknown").each(function(){
		var id = $(this).attr('rel')
		var split = id.split(':')
		switch(split[0]) {
			case 'tvdb':
				var url = ""
				break
			case 'tmdb':
				var url = "http://query.yahooapis.com/v1/public/yql?q=use%20'http%3A%2F%2Fvideoscrobbler.heroku.com%2Fyql%2Ftmdb.xml'%20as%20tmdb%3B%20select%20*%20from%20tmdb%20where%20movieid%3D%22"+split[1]+"%22%3B&format=json&callback=?"
				break
			case 'http':
				var url = ""
				break
			default:
				return
		}
		
		$.getJSON(url,function(data){
			var img = document.createElement('img')
			$(img).bind('load',function() {
				$('li[rel="'+data.query.results.video['id']+'"] img.poster').attr('src',data.query.results.video['poster'])
			})
			img.src = data.query.results.video['poster']
			$('li[rel="'+data.query.results.video['id']+'"] strong').text(data.query.results.video['title'])
		})
	})
})