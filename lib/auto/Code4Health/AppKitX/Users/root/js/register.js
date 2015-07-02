$(function() {
	$(':input[name=primary_organisation]').autocomplete({
		serviceUrl: '/organisations/search?want_other=1',
		ajaxSettings: {
			dataType: "json"
		},
		minChars: 3,
        onSelect: function (suggestion) {
            $(this).val(suggestion.value);
            $(':input[name=primary_organisation_id]').val(suggestion.data);
            if (suggestion.data == '') {
                // OTHER
                $(':input[name=primary_organisation_other]').closest('.form-group').removeClass('hidden');
            }
            else {
                $(':input[name=primary_organisation_other]').closest('.form-group').addClass('hidden');
            }
        }
    });
});
