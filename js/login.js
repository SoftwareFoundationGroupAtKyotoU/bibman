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
        dataType: 'json',
        type: 'POST',
        url: './api/login.cgi'
      }).done(function (cert) {
        console.log(cert.is_admin);
        sessionStorage["is_admin"] = cert.is_admin;
        document.location = './~' + cert.account + '/';
      }).fail(function () {
        window.alert('アカウントもしくはパスワードが不正です．');
      });
    }

    return false;
  });
});
