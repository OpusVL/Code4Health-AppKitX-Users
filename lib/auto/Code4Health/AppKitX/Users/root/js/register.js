$(function() {
	$(':input[name=primary_organisation]').autocomplete({
		serviceUrl: '/organisations/search',
		ajaxSettings: {
			dataType: "json"
		},
		minChars: 3,
        onSelect: function (suggestion) {
            $(this).val(suggestion.value);
            $(':input[name=primary_organisation_id]').val(suggestion.data);
        }
    });
});
