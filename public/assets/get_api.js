$(document).ready(function() {
	$('#getapi').submit(function(e) {
		e.preventDefault()
		if ($('#appname').val() == '' || $('#description').val() == '') {
			error({'message':'App name and description must be filled'})
			break
		}
		
		$.ajax({
			url: $(this).attr('action'),
			dataType: 'json',
			data: $(this).serialize(),
			success: function(data) {
				switch (data['action']) {
					case 'get_api':
						document.location.href = '/api/account'
						break
				}
			},
			error: function(data) {error(data)}
		})
	})
})

function error(data) {
	$('#message').text(data['message'])
	$('#message').addClass('error')
}