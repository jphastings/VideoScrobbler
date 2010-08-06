var db = null;

$(document).ready(function() {
	$("time.timeago").timeago();
	
	initDatabase();
	
	$("li.video.unknown").each(function(){
		tryGettingFromDB($(this).attr('rel'))
	})
})

function addMetadata(details) {
	var img = document.createElement('img')
	$(img).bind('load',function() {
		$('li[rel="'+details['id']+'"] img.poster').attr('src',details['poster'])
	})
	img.src = details['poster']
	$('li[rel="'+details['id']+'"] strong').text(details['title'])
	$('li[rel="'+details['id']+'"]').parent().attr('href',details['url'])
}

function tryGettingFromDB(remote_id) {
	if (window.openDatabase) {
		// Does this remote_id exist in the local database?
		db.transaction(function (transaction) {
			transaction.executeSql("SELECT * FROM VSids WHERE id=?;", [remote_id], function(transaction,results){
				if (results.rows.length == 0) {
					getFromYQL(remote_id)
				} else {
					addMetadata(results.rows.item(0))
				}
			});
	    });
	} else {
		getFromYQL(remote_id)
	}
}

function getFromYQL(remote_id) {
	var split = remote_id.split(':')
	switch(split[0]) {
		case 'tvdb':
			var url = "http://query.yahooapis.com/v1/public/yql?q=use%20'http%3A%2F%2Fvideoscrobbler.heroku.com%2Fyql%2Ftvdb.xml%3Fd'%20as%20tvdb%3B%20select%20*%20from%20tvdb%20where%20episodeid%3D"+split[1]+"%20and%20api_key%3D'E319EC33BBD28757'&format=json&callback=?"
			break
		case 'tmdb':
			var url = "http://query.yahooapis.com/v1/public/yql?q=use%20'http%3A%2F%2Fvideoscrobbler.heroku.com%2Fyql%2Ftmdb.xml'%20as%20tmdb%3B%20select%20*%20from%20tmdb%20where%20movieid%3D%22"+split[1]+"%22%3B&format=json&callback=?"
			break
		case 'http':
			var url = "http://query.yahooapis.com/v1/public/yql?q=use%20'http%3A%2F%2Fvideoscrobbler.heroku.com%2Fyql%2Furl.xml%3Fb'%20as%20sites%3B%20select%20*%20from%20sites%20where%20url%3D'"+remote_id+"'&format=json&callback=?"
			break
		default:
			return
	}
	
	$.getJSON(url,function(data){
		try {
			if (window.openDatabase) {
				db.transaction(function (transaction) {
					transaction.executeSql("INSERT INTO VSids(id, poster, title,url) VALUES (?, ?, ?)", [data.query.results.video['id'], data.query.results.video['poster'], data.query.results.video['title'], data.query.results.video['url']]);  
			    });
			}		
		
			addMetadata(data.query.results.video)
		} catch(e) {
			console.log("No results for "+remote_id)
		}
	})
}

// Database things
function initDatabase() {
	try {
	    if (window.openDatabase) {
	        db = openDatabase('VideoScrobblerMetadata', '1.0','VideoScrobbler Tv and Film database', 100000);
			
			db.transaction(function (transaction) {  
				transaction.executeSql('CREATE TABLE IF NOT EXISTS VSids(id VARCHAR(255) NOT NULL PRIMARY KEY, poster TEXT NOT NULL,title TEXT NOT NULL,url TEXT NOT NULL);', []);  
			});
	    }
	} catch(e) {

	    if (e == 2) {
	        // Version number mismatch.
	        console.log("Invalid database version.");
	    } else {
	        console.log("Unknown error "+e+".");
	    }
	    return;
	}
}