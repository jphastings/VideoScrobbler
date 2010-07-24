$(document).ready(function() {
	$("time.timeago").timeago();
	
	$("li.video.unknown").each(function(){
		var id = $(this).attr('rel')
		var split = id.split(':')
		switch(split[0]) {
			case 'tvdb':
				var url = ""
				break;
			case 'tmdb':
				var url = "http://"
				break;
			case 'http':
				var url = id
				break
		}
		
		
	})
})