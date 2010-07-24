$(document).ready(function() {
	$("input:password").chromaHash({bars: 4, salt:"c1d49ca3d17aaa9aa04ed3c005908184", minimum:6});
	
	choose(window.location.hash.substring(1))
	
	$('#auth input:radio').click(function(){
		choose($('#auth input:radio:checked').val())
	})
	
	$('#auth').submit(function(e) {
		e.preventDefault()
		if ($('#password').val().length < 6) {
			error({'message':'Passwords must be at least 6 characters long'})
			break
		}
		if ($(this).attr('action') == 'signup' && $('#password').val() != $('#confirm-password').val()) {
			error({'message':'The new passwords don\'t match'})
			break
		}
		$.ajax({
			url: $(this).attr('action'),
			dataType: 'json',
			data: $(this).serialize(),
			success: function(data) {
				switch (data['action']) {
					case 'login':
						document.location.href = '/users/'+data['username']
						break
					case 'signup':
						document.location.href = '/account'
						break
				}
			},
			error: function(data) {
				$('#message').data('original',$('#message').text())
				$('#message').text(data['message'])
				$('#message').addClass('error')
			}
		})
	})
})

function choose(side) {
	side = (side == 'signup') ? 'signup' : 'login'
	other = (side == 'login') ? 'signup' : 'login'

	$('#message').removeClass('error')
	$('#message').text($('#message').data('original'))
	
	$('#choose'+side)[0].checked = true
	$('.'+side).fadeIn()
	$('.'+other).fadeOut()
	$('#submit').attr('value',(side == 'login') ? "Log In" : "Sign Up")
}


function error(data) {
	$('#message').text(data['message'])
	$('#message').addClass('error')
}