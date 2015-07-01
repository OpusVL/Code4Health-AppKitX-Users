$(function () {
	$(':input.organisation-autocomplete').autocomplete({
		serviceUrl: '/organisations/search',
		minChars: 3,
	});
});
