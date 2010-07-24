$(document).ready(function() {
	$("input:password").chromaHash({bars: 4, salt:"c1d49ca3d17aaa9aa04ed3c005908184", minimum:6});
	
	$('#pw').submit(function(e) {
		e.preventDefault()
		if ($('#oldpassword').val().length < 6 || $('#password').val().length < 6) {
			error({'message':'Passwords must be at least 6 characters long'})
			break
		}
		if ($('#password').val() != $('#confirm-password').val()) {
			error({'message':'The new passwords don\'t match'})
			break
		}
		if ($('#oldpassword').val() == $('#password').val()) {
			error({'message':'The new and old passwords are the same'})
			break
		}
		
		$.ajax({
			url: $(this).attr('action'),
			dataType: 'json',
			data: $(this).serialize(),
			success: function(data) {
				switch (data['action']) {
					case 'changepw':
						$('input').val('')
						$('#message').addClass('completed')
						$('#message').text("Password updated")
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