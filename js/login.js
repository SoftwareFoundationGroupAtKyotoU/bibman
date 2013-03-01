'use strict';

$(document).ready(function () {

  var $account = $('#account');

  function fail() {
    window.alert('アカウント名が不正です．');
  }

  function succeed(account) {
    document.location = './~' + account + '/';
  }

  $('#login').bind('submit', function () {
    var account = $account.val();

    if (account === '') {
      window.alert('アカウント名が入力されていません．');
    }
    else {
      $.ajax({
        data: { account: account },
        dataType: 'text',
        error: fail,
        success: succeed,
        type: 'GET',
        url: './api/account-cert.cgi'
      });
    }

    return false;
  });
});
