$(function () {
    $('.record-community').each(function () {
        // add a button to leave the community.
        var button = $('<a href="#" class="btn btn-danger">').text('Leave');
        var $item = $(this);
        var community = this.dataset.code;
        $item.append(button);
        button.click(function() {
            $.post('/modules/users/leave_community', { community: community }, function(data) {
                if(data.success) {
                    $item.remove();
                }
                // FIXME: display an error if there was a failure.
            });
            return false;
        });
    });
});

