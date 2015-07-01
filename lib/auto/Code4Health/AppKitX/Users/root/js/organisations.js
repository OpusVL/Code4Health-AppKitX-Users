$(function () {
	var update_user_org = curry(function(url, org_code) {
		return $.ajax({
			url: url,
			method: 'post',
			data: {
				code: org_code
			},
			dataType: "json"
		});
	});

	var update_user_primary_org = update_user_org('/organisations/user_primary_org'),
		add_user_secondary_org = update_user_org('/organisations/user_secondary_org');

	function remove_user_secondary_org(org_code) {
		return $.ajax({
			url: '/organisations/user_secondary_org/' + org_code,
			method: 'delete',
			dataType: "json"
		});
	}

	$(':input[name=primary_organisation]').autocomplete({
		serviceUrl: '/organisations/search',
		ajaxSettings: {
			dataType: "json"
		},
		minChars: 3,
		onSelect: function(selection) {
			var indicator = $(this).closest('.input-group').find('.saved-indicator span');

			indicator.removeClass('glyphicon-ok glyphicon-alert glyphicon-hourglass').addClass('glyphicon-refresh');

			update_user_primary_org(
				selection.data
			)
			.done(function() {
				indicator.removeClass('glyphicon-refresh').addClass('glyphicon-ok');
			})
			.error(function() {
				indicator.removeClass('glyphicon-refresh').addClass('glyphicon-alert');
			});
		},
		onSearchStart: function() {
			var indicator = $(this).closest('.input-group').find('.saved-indicator span');

			indicator.removeClass('glyphicon-ok glyphicon-alert').addClass('glyphicon-hourglass');

		}
	});
});
