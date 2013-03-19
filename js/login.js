'use strict';

$(document).ready(function () {

  var $account = $('#account');
  var $password = $('#password');

  $('#login').bind('submit', function () {
    var account = $account.val();
    var password = $password.val();

    if (account === '') {
      window.alert('アカウント名が入力されていません．');
    }
    else if (password === '') {
      window.alert('パスワードが入力されていません．');
    }
    else {
      $.ajax({
        data: { account: account, password: password },
        dataType: 'text',
        type: 'POST',
        url: './api/login.cgi'
      }).done(function (account) {
        document.location = './~' + account + '/';
      }).fail(function () {
        window.alert('アカウント名が不正です．');
      });
    }

    return false;
  });
});
