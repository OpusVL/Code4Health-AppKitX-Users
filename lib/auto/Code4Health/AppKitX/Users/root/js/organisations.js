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
        serviceUrl: '/organisations/search?want_other=1',
        ajaxSettings: {
            dataType: "json"
        },
        minChars: 3,
        onSelect: function(selection) {
            var indicator = $(this).closest('.input-group').find('.saved-indicator span');

            indicator.removeClass('glyphicon-floppy-saved glyphicon-alert glyphicon-hourglass').addClass('glyphicon-refresh');

            update_user_primary_org(
                selection.data
            )
            .done(function() {
                indicator.removeClass('glyphicon-refresh').addClass('glyphicon-floppy-saved');
            })
            .error(function() {
                indicator.removeClass('glyphicon-refresh').addClass('glyphicon-alert');
            });

            if (selection.data == '') {
                $(':input[name=primary_organisation_other]').closest('.form-group').removeClass('hidden');
            }
            else {
                $(':input[name=primary_organisation_other]').closest('.form-group').addClass('hidden');
            }
        },
        onSearchStart: function() {
            var indicator = $(this).closest('.input-group').find('.saved-indicator span');

            indicator.removeClass('glyphicon-floppy-saved glyphicon-alert').addClass('glyphicon-hourglass');

        }
    });

    var add_secondary_org = curry(function(selected_data, ajax_data) {
        var $item = $('.js-template.secondary-org').clone();
        $item.find('input').val(selected_data.value);
        $item.find('input').data('org-code', selected_data.data);
        $item.removeClass('js-template');

        var $list = $('.secondary-orgs');
        var $list_items = $list.find('.secondary-org').not('.js-template');

        if (! $list_items.length) {
            $list.append($item);
        }
        else {
            var $prior;
            // standard insert-sort search thing
            $list_items.each(function(i, obj) {
                if ($(obj).find('input').val().replace(/,/g, '').localeCompare(selected_data.value) >= 0) {
                    return false;
                }
                $prior = $(obj);
            });

            if ($prior) {
                $prior.after($item);
            }
            else {
                $list.prepend($item);
            }
        }
    });

    $(':input[name=secondary_organisation]').autocomplete({
        serviceUrl: '/organisations/search',
        ajaxSettings: {
            dataType: "json"
        },
        minChars: 3,
        onSelect: function(selection) {
            add_user_secondary_org(selection.data)
                .done(add_secondary_org(selection));
        },
    });

    $(document).on('click', '.secondary-org button', function() {
        var $this = $(this),
            code = $this.closest('.secondary-org').find('input').data('org-code');
        remove_user_secondary_org(code);

        $this.closest('li').remove();
    });

    var update_user_org_other = curry(function(org_name) {
        return $.ajax({
            url: '/organisations/user_primary_org',
            method: 'post',
            dataType: 'json',
            data: {
                other: org_name
            }
        });
    });

    var update_org_other = curry(function(org_name, indicator) {
        indicator.removeClass('glyphicon-floppy-disk').addClass('glyphicon-refresh');
        update_user_org_other(org_name)
            .done(function() {
                indicator.removeClass('glyphicon-refresh').addClass('glyphicon-floppy-saved');
            })
            .error(function() {
                indicator.removeClass('glyphicon-refresh').addClass('glyphicon-alert');
            });
    });

    $(':input[name=primary_organisation_other]').on('keypress', function(e) {
        var $this = $(this);

        if (e.keyCode == 13) {
            e.preventDefault();
            update_org_other($this.val(), $this.closest('.form-group').find('.saved-indicator .glyphicon'));
        }
    });
});
